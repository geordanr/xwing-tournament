Q = require 'q'
uuid = require 'node-uuid'

Doc = require './doc'

_type = 'tournament'
_properties = [ 'name', 'event_start_timestamp', 'event_end_timestamp', 'description', 'organizer_email', 'organizer_user_id' ]

exports.use = (db) ->
    exports.db = db
    Doc.use exports.db

exports.save = (doc) ->
    Doc.saveDoc doc, _type, _properties

exports.fetch = (id) ->
    Doc.fetchDoc id, _type
