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
    doc.event_start_timestamp = parseInt doc.event_start_timestamp
    doc.event_end_timestamp = parseInt doc.event_end_timestamp
    throw "Start timestamp required" unless doc.event_start_timestamp?
    throw "End timestamp required" unless doc.event_end_timestamp?
    Doc.saveDoc doc, _type, _properties

exports.fetch = (id) ->
    Doc.fetchDoc id, _type

exports.getAll = (after=null) ->
    try
        after = parseInt(after)
    catch
        after = null
    after ?= parseInt((new Date()).getTime() / 1000)

    Doc.view 'tournament', 'byStartTimestamp', {startKey: after, include_docs: true}
    .then (rows) ->
        (row.doc for row in rows)

exports.getParticipants = (tournament_id) ->
    Doc.view 'tournament', 'participants', {startkey: [tournament_id], endkey: [tournament_id, {}]}
