Doc = require './doc'
Tournament = require './tournament'

_type = 'participant'
_properties = [
    'tournament_id'
    'user_id'
    'participant_email'
]

exports.enterTournament = (tournament_id, user_id, participant_email) ->
    # There can be only one tournament entry per user
    exports.entryExists user_id, tournament_id
    .then (isEntered) ->
        if isEntered
            throw new Error "User #{user_id} is already entered in tournament #{tournament_id}"
    .then ->
        doc =
            _id: "#{_type}--#{tournament_id}--#{user_id}"
            tournament_id: tournament_id
            user_id: user_id
            participant_email: participant_email
        Doc.saveDoc doc, _type, _properties

exports.getEnteredTournaments = (user_id) ->
    Doc.view 'participant', 'enteredTournaments', {startkey: [user_id], endkey: [user_id, {}]}

exports.entryExists = (user_id, tournament_id) ->
    Doc.view 'participant', 'enteredTournaments'
    .then ->
        Doc.view 'participant', 'enteredTournaments', {key: [user_id, tournament_id]}
    .then (rows) ->
        rows.length > 0

#exports.save = (doc) ->
#    Doc.saveDoc doc, _type, _properties
#
#exports.fetch = (id) ->
#    Doc.fetchDoc id, _type
