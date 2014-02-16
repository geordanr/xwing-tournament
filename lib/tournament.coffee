Q = require 'q'
uuid = require 'node-uuid'

{Doc} = require './doc'

exports.Tournament =
    _type: 'tournament'
    _properties: [ 'name', 'description', 'organizer_email', 'organizer_user_id' ]

    save: (db, doc) ->
        Doc.saveDoc db, doc, exports.Tournament._type, exports.Tournament._properties

    fetch: (db, id) ->
        Doc.fetchDoc db, id, exports.Tournament._type
