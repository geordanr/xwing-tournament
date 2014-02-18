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
                        email: doc.participant_email
            '''

exports.createViews = ->
    deferred = Q.defer()

    Doc.saveWithRetries design_doc
    .then (res) ->
        deferred.resolve res
    .fail (err) ->
        console.error "Failed to save design doc to #{Doc.db.config.db}: #{err}"
        Doc.fetchDoc design_doc._id
        .then (old_doc) ->
            #console.log "Fetched old design doc"
            #console.dir old_doc
            design_doc._rev = old_doc._rev
            #console.log "Saving design doc with new rev #{design_doc._rev}"
            deferred.resolve Doc.saveRaw design_doc
        .fail (err) ->
            console.error "Failed to fetch design doc #{design_doc._id}"
            deferred.reject err

    deferred.promise
