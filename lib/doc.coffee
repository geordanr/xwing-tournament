Q = require 'q'
uuid = require 'node-uuid'

exports.use = (db) ->
    #console.trace "Doc asked to use #{db.config.db}"
    throw new Error "No db given" unless db?
    exports.db = db

exports.saveRaw = (doc) ->
    deferred = Q.defer()

    exports.db.insert doc, (err, body) ->
        if err
            deferred.reject err
        else
            #console.log "saved doc #{body.id} to #{exports.db.config.db}"
            deferred.resolve
                id: body.id
                rev: body.rev

    deferred.promise

exports.saveWithRetries = (doc, max_retries=5) ->
    # Saves doc, refetching doc to get _rev and retrying if necessary
    deferred = Q.defer()
    max_retries = parseInt max_retries

    retry_func = (deferred, doc, max_retries) ->
        exports.saveRaw doc
        .then (res) ->
            deferred.resolve res
        .fail (err) ->
            if err.indexOf('Document update conflict') >= 0
                if max_retries > 0
                    console.warn "Error saving doc #{doc._id}: '#{err}', #{max_retries} retries remaining"
                    setTimeout ->
                        exports.fetchDoc doc._id
                        .then (res) ->
                            doc._rev = res._rev
                            retry_func deferred, doc, (max_retries - 1)
                        .fail (err) ->
                            # Offending doc is gone
                            console.warn "Conflicting document is gone for #{doc._id}, saving with no _rev"
                            delete doc._rev
                            retry_func deferred, doc, (max_retries - 1)
                    , 100
                else
                    console.error "Error saving doc #{doc._id}:\n#{err}\nGiving up immediately"
                    deferred.reject err
            else
                console.error "Error saving doc #{doc._id}: #{err} (no more retries)"
                deferred.reject err

    retry_func deferred, doc, max_retries

    deferred.promise

exports.saveDoc = (doc, type, required_properties=[]) ->
    deferred = Q.defer()

    for property in required_properties
        if property not of doc
            deferred.reject new Error "Required property '#{property}' missing"
    doc._id = "#{type}-#{uuid.v4()}" unless '_id' of doc
    if doc.type?
        if doc.type != type
            deferred.reject new Error "Attempt to save doc with type #{type} when it already is of type #{doc.type}"
    else
        doc.type = type

    deferred.resolve exports.saveWithRetries(doc)

    deferred.promise

exports.fetchDoc = (id, assert_type=null) ->
    deferred = Q.defer()

    exports.db.get id, (err, doc) ->
        if err
            deferred.reject err
        else if assert_type? and assert_type != doc.type
            deferred.reject new Error "Expected doc type #{assert_type} but got #{doc.type}"
        else
            deferred.resolve doc

    deferred.promise

exports.destroyDoc = (id, rev) ->
    deferred = Q.defer()

    exports.db.destroy id, rev, (err, body) ->
        if err
            deferred.reject err
        else
            deferred.resolve body

    deferred.promise

exports.view = (design, view, params={}) ->
    deferred = Q.defer()

    exports.db.view design, view, params, (err, body) ->
        if err
            console.error "error viewing #{design}/#{view}: #{err}"
            deferred.reject err
        else
            deferred.resolve body.rows

    deferred.promise
