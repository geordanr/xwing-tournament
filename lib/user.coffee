Doc = require './doc'

_type = 'user'
_properties = [
    'oauth_strategy'
    'oauth_id'
    'email'
]

exports.find = (strategy, id) ->
    Doc.view 'user', 'byStrategyId', {key: [strategy, id]}
    .then (rows) ->
        if rows.length > 0
            exports.fetch rows[0].id
        else
            null

exports.save = (doc) ->
    doc.email ?= null
    Doc.saveDoc doc, _type, _properties

exports.fetch = (id) ->
    Doc.fetchDoc id, _type

exports.getEnteredTournaments = (user_id) ->

exports.getOwnedTournaments = (user_id) ->
