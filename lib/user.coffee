Doc = require './doc'

_type = 'user'
_properties = [
    'oauth_strategy'
    'oauth_id'
]

exports.save = (doc) ->
    Doc.saveDoc doc, _type, _properties

exports.fetch = (id) ->
    Doc.fetchDoc id, _type
