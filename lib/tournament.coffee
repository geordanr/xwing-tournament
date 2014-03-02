Q = require 'q'
Doc = require './doc'
Match = require './match'
Participant = require './participant'

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
    deferred = Q.defer()

    doc.event_start_timestamp = parseInt doc.event_start_timestamp
    doc.event_end_timestamp = parseInt doc.event_end_timestamp
    try
        throw new Error "Name required" unless doc.name
        throw new Error "Start timestamp required" unless doc.event_start_timestamp?
        throw new Error "End timestamp required" unless doc.event_end_timestamp?
        throw new Error "Tournament must end after it begins" unless doc.event_start_timestamp < doc.event_end_timestamp
        deferred.resolve Doc.saveDoc doc, _type, _properties
    catch err
        deferred.reject err


    deferred.promise

exports.fetch = (id) ->
    Doc.fetchDoc id, _type

exports.getAll = (after=null) ->
    try
        after = parseInt(after)
    catch
        after = null
    after ?= parseInt((new Date()).getTime() / 1000)

    Doc.view 'tournament', 'byStartTimestamp', {startkey: after, include_docs: true}
    .then (rows) ->
        (row.doc for row in rows)

exports.getParticipants = (tournament_id) ->
    Doc.view 'tournament', 'participants', {startkey: [tournament_id], endkey: [tournament_id, {}]}
    .then (rows) ->
        Q.all(Participant.fetch(row.id) for row in rows)
    .spread (participants...) ->
        participants

exports.getRounds = (tournament_id) ->
    Doc.view 'round', 'byTournament', {group: true, key: tournament_id}
    .then (rows) ->
        rows[0].value[tournament_id]

exports.getMatches = (tournament_id, round) ->
    Doc.view 'match', 'byTournamentRound', {key: [tournament_id, round]}
    .then (rows) ->
        Q.all(Match.fetch(row.id) for row in rows)
    .spread (matches...) ->
        matches
