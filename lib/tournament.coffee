Doc = require './doc'

_type = 'tournament'
_properties = [
    'name'
    'event_start_timestamp'
    'event_end_timestamp'
    'description'
    'organizer_email'
    'organizer_user_id'
]

exports.save = (doc) ->
    Doc.saveDoc doc, _type, _properties

exports.fetch = (id) ->
    Doc.fetchDoc id, _type

exports.getParticipants = (tournament_id) ->
    Doc.view 'tournament', 'participants', {startkey: [tournament_id], endkey: [tournament_id, {}]}
