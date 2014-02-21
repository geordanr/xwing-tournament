Doc = require './doc'

_type = 'list'
_properties = [
    "tournament_id"
    "participant_id"
    "ships"
    "url"
    "approved"
]

exports.save = (doc) ->
    Doc.saveDoc doc, _type, _properties

exports.fetch = (id) ->
    Doc.fetchDoc id, _type
