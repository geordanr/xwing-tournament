Q = require 'q'
Doc = require './doc'

_type = 'match'
_properties = [
    "tournament_id"
    "round"
    "participants"
    "finished"
    "result"
    "awarded_points"
]

exports.save = (doc) ->
    throw new Error "Tournament ID required" unless doc.tournament_id?
    throw new Error "Round required" unless doc.round?

    doc.awarded_points ?= null
    doc.finished ?= false
    doc.result ?= null
    try
        for participant in doc.participants
            throw new Error "Participant ID required" unless participant.participant_id?
            throw new Error "List ID required" unless participant.list_id?
        if doc.finished and not (doc.awarded_points? and doc.awarded_points.length > 0)
            throw new Error "Match is finished but no points were awarded"
        Doc.saveDoc doc, _type, _properties
    catch err
        Q.fcall ->
            throw err

exports.fetch = (id) ->
    Doc.fetchDoc id, _type

defaultAwarderFunc = (participants, winner_id, result) ->
    awarded_points = {}
    for participant in participants
        awarded_points[participant_id] = if participant.participant_id == winner_id then 1 else 0
    awarded_points

exports.finish = (match_id, winner_participant_id, result, pointsAwarderFunc=defaultAwarderFunc) ->
    exports.fetch match_id
    .then (match) ->
        match.finished = true
        match.winner = winner_participant_id
        match.result = result
        match.awarded_points = pointsAwarderFunc match.participants, winner_participant_id, result
        Match.save match
