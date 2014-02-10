{Doc} = require './doc'

class exports.Participant extends Doc
    constructor: (args) ->
        @doc_keys = [ 'tournament_id', 'user_id', 'email', ]
        @type = 'participant'
        super args

    @fetch: (db, id, cb) ->
        Doc.fetch db, id, exports.Participant, cb
