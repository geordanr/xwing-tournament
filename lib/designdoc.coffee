Q = require 'q'
Doc = require './doc.coffee'

design_doc =
    _id: '_design/tournament'
    language: 'coffeescript'
    views:
        tournamentsByStart:
            map: '''
                (doc) ->
                    if doc.type == 'tournament'
                        emit doc.event_start_timestamp, null
            '''
        listsByTournamentParticipant:
            map: '''
                (doc) ->
                    if doc.type == 'list'
                        emit [doc.tournament_id, doc.participant_id],
                        ships: (x.ship for x in doc.summary)
            '''
        matchByTournamentRound:
            map: '''
                (doc) ->
                    if doc.type == 'match'
                        emit [doc.tournament_id, doc.round],
                        finished: doc.finished,
                        participants: doc.participants,
                        result: doc.result,
                        winner: doc.winner
            '''
        participantsByTournament:
            map: '''
                (doc) ->
                    if doc.type == 'participant'
                        emit doc.tournament_id,
                        email: doc.email
            '''

exports.createViews = (db) ->
    Doc.use db

    Doc.saveRaw design_doc
    .fail ->
        Doc.fetchDoc design_doc._id
        .then (old_doc) ->
            design_doc._rev = old_doc._rev
            Doc.saveRaw design_doc
