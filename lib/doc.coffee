uuid = require 'node-uuid'

class exports.Doc
    constructor: (args) ->
        @_id = args._id ? "#{@type}-#{uuid.v4()}"
        @_rev = args._rev ? null
        @data =
            type: @type
        for key in @doc_keys
            @data[key] = args[key]

    @fetch: (db, id, cls, cb) ->
        # Provide class to instantiate in cls
        # cb called with new instance
        db.get id, (err, doc) ->
            if err
                console.log "Error fetching ID #{id}: #{err}"
            else
                cb(new cls doc)

    saveTo: (db, cb) ->
        # Runs cb when done
        doc =
            _id: @_id
            type: @type
        doc._rev = @_rev if @_rev?

        for k, v of @data
            doc[k] = v

        db.insert doc, cb
