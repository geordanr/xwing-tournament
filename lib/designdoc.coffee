design_doc =
    language: 'coffeescript'
    views:
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