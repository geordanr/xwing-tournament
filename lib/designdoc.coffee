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
                            emit [doc.tournament_id, doc.participant_id],
                            ships: (x.ship for x in doc.summary)
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
                                tournament_id: doc.tournament_id
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
