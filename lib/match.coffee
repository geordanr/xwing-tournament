Q = require 'q'
Doc = require './doc'
List = require './list'

_type = 'match'
_properties = [
    "tournament_id"
    "round"
    "participants"
    "finished"
    "result"
    "awarded_points"
]

exports.new = (tournament_id, round, list1_id, list2_id) ->
    throw new Error "Tournament ID required" unless tournament_id?
    throw new Error "Round required" unless round?

    Q.all [
        List.fetch list1_id
        if list2_id then List.fetch list2_id else null
    ]
    .spread (list1, list2) ->
        exports.save
            tournament_id: tournament_id
            round: round
            participants: [
                {
                    participant_id: list1.participant_id
                    list_id: list1._id
                }
                {
                    participant_id: list2?.participant_id ? null
                    list_id: list2?._id ? null
                }
            ]
            finished: false
            result: null
            awarded_points: null

exports.bye = (tournament_id, round, list_id, result="Bye", pointsAwarderFunc=defaultAwarderFunc) ->
    exports.new tournament_id, round, list_id, null
    .then (res) ->
        exports.fetch res.id
    .then (match) ->
        exports.finish match._id, match.participants[0].participant_id, result, pointsAwarderFunc

exports.save = (doc) ->
    try
        if doc.finished and not doc.awarded_points?
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
        switch result
            when "Match Win"
                awarded_points[participant.participant_id] = if participant.participant_id == winner_id then 5 else 0
            when "Modified Match Win"
                awarded_points[participant.participant_id] = if participant.participant_id == winner_id then 3 else 0
            when "Bye"
                awarded_points[participant.participant_id] = if participant.participant_id == winner_id then 5 else 0
            when "Draw"
                awarded_points[participant.participant_id] = 1
    awarded_points

exports.finish = (match_id, winner_participant_id, result, pointsAwarderFunc=defaultAwarderFunc) ->
    exports.fetch match_id
    .then (match) ->
        match.finished = true
        match.winner = winner_participant_id
        match.result = result
        match.awarded_points = pointsAwarderFunc match.participants, winner_participant_id, result
        exports.save match
