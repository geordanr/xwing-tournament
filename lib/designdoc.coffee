Q = require 'q'
Doc = require './doc.coffee'

design_docs =
    'tournament':
        language: 'coffeescript'
        views:
            byStartTimestamp:
                map: '''
                    (doc) ->
                        if doc.type == 'tournament'
                            emit doc.event_start_timestamp, null
                '''
            byOwner:
                map: '''
                    (doc) ->
                        if doc.type == 'tournament'
                            emit [
                                doc.organizer_user_id
                                doc.event_start_timestamp
                            ], null
                '''
            participants:
                map: '''
                    (doc) ->
                        if doc.type == 'participant'
                            emit [
                                doc.tournament_id
                                doc.user_id
                            ],
                                name: doc.name
                                user_id: doc.user_id
                                participant_email: doc.participant_email
                '''

    'list':
        language: 'coffeescript'
        views:
            byTournamentParticipant:
                map: '''
                    (doc) ->
                        if doc.type == 'list'
                            counts = {}
                            for ship in doc.ships
                                counts[ship.ship] ?= 0
                                counts[ship.ship]++

                            sorted_ships = Object.keys(counts).sort()

                            emit [doc.tournament_id, doc.participant_id],
                                ships: ("#{counts[ship]}x #{ship}" for ship in sorted_ships).join ', '
                                url: doc.url
                '''

    'round':
        language: 'coffeescript'
        views:
            byTournament:
                map: '''
                    (doc) ->
                        if doc.type == 'match'
                            emit doc.tournament_id, doc.round
                '''
                reduce: '''
                    (keys, values, rereduce) ->
                        tourneys = {}
                        if rereduce
                            for value of values
                                for tournament_id, rounds of value
                                    tourneys[tournament_id] ?= []
                                    for round in rounds
                                        tourneys[tournament_id].push round if round not in tourneys[tournament_id]
                        else
                            for [tournament_id, doc_id], i in keys
                                tourneys[tournament_id] ?= []
                                tourneys[tournament_id].push values[i] if values[i] not in tourneys[tournament_id]
                        for tournament_id, rounds of tourneys
                            tourneys[tournament_id] = rounds.sort()
                        tourneys
                '''

    'match':
        language: 'coffeescript'
        views:
            byTournamentRound:
                map: '''
                    (doc) ->
                        if doc.type == 'match'
                            emit [doc.tournament_id, doc.round],
                                finished: doc.finished,
                                participants: doc.participants,
                                result: doc.result,
                                winner: doc.winner
                                awarded_points: doc.awarded_points
                '''

    'participant':
        language: 'coffeescript'
        views:
            enteredTournaments:
                map: '''
                    (doc) ->
                        if doc.type == 'participant'
                            emit [
                                doc.user_id
                                doc.tournament_id
                            ],
                                name: doc.name
                                tournament_id: doc.tournament_id
                '''

    'user':
        language: 'coffeescript'
        views:
            byStrategyId:
                map: '''
                    (doc) ->
                        if doc.type == 'user'
                            emit [
                                doc.oauth_strategy
                                doc.oauth_id
                            ], null
                '''

exports.createViews = ->
    Q.all(applyDesignDoc(name, doc) for name, doc of design_docs)

applyDesignDoc = (name, doc) ->
    deferred = Q.defer()

    doc._id = "_design/#{name}"
    Doc.saveWithRetries doc
    .then (res) ->
        deferred.resolve res
    .fail (err) ->
        console.error "Failed to save design doc to #{Doc.db.config.db}: #{err}"
        Doc.fetchDoc doc._id
        .then (old_doc) ->
            doc._rev = old_doc._rev
            deferred.resolve Doc.saveWithRetries doc
        .fail (err) ->
            console.error "Failed to fetch design doc #{doc._id} from #{Doc.db.config.db}"
            deferred.reject err

    deferred.promise
