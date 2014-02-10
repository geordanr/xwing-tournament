{Doc} = require './doc'

class exports.Tournament extends Doc
    constructor: (args) ->
        @doc_keys = [ 'name', 'description', 'organizer_user_id', 'organizer_email', ]
        @type = 'tournament'
        super args

    @fetch: (db, id, cb) ->
        Doc.fetch db, id, exports.Tournament, cb
