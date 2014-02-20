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
    exports.checkIfEntryExists tournament_id, user_id
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

exports.revokeEntry = (tournament_id, user_id) ->
    exports.getEntry tournament_id, user_id
    .then (participant) ->
        Doc.destroyDoc participant._id, participant._rev
    # TODO - destroy other stuff that refers to this, like submitted lists

exports.getEntry = (tournament_id, user_id) ->
    Doc.view 'participant', 'enteredTournaments'
    .then ->
        Doc.view 'participant', 'enteredTournaments', {key: [user_id, tournament_id]}
    .then (rows) ->
        if rows.length > 0
            Doc.fetchDoc rows[0].id, _type
        else
            throw new Error "User #{user_id} was not entered in tournament #{tournament_id}"

exports.getEnteredTournaments = (user_id) ->
    Doc.view 'participant', 'enteredTournaments', {startkey: [user_id], endkey: [user_id, {}]}

exports.checkIfEntryExists = (tournament_id, user_id) ->
    exports.getEntry tournament_id, user_id
    .then (res) ->
        true
    .fail ->
        false

#exports.save = (doc) ->
#    Doc.saveDoc doc, _type, _properties
#
#exports.fetch = (id) ->
#    Doc.fetchDoc id, _type
