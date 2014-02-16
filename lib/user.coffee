Q = require 'q'
uuid = require 'node-uuid'

{Doc} = require './doc'

exports.User =
    _type: 'user'
    _properties: []

    save: (db, doc) ->
        Doc.saveDoc db, doc, exports.User._type, exports.User._properties

    fetch: (db, id) ->
        Doc.fetchDoc db, id, exports.User._type
