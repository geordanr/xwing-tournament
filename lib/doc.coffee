Q = require 'q'
uuid = require 'node-uuid'

exports.Doc =
    saveRaw: (db, doc) ->
        deferred = Q.defer()

        db.insert doc, (err, body) ->
            if err
                deferred.reject err
            else
                deferred.resolve
                    id: body.id
                    rev: body.rev

        deferred.promise

    saveDoc: (db, doc, type, required_properties=[]) ->
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

        deferred.resolve exports.Doc.saveRaw(db, doc)

        deferred.promise

    fetchDoc: (db, id, assert_type=null) ->
        deferred = Q.defer()

        db.get id, (err, doc) ->
            if err
                deferred.reject err
            else if assert_type? and assert_type != doc.type
                deferred.reject new Error "Expected doc type #{assert_type} but got #{doc.type}"
            else
                deferred.resolve doc

        deferred.promise

    destroyDoc: (db, id, rev) ->
        deferred = Q.defer()

        db.destroy id, rev, (err, body) ->
            if err
                deferred.reject err
            else
                deferred.resolve body

        deferred.promise
