Doc = require './doc'

_type = 'participant'
_properties = [
    'tournament_id'
    'user_id'
    'participant_email'
]

exports.enterTournament = (tournament_id, user_id, participant_email) ->
    # There can be only one tournament entry per user
    doc =
        _id: "#{_type}--#{tournament_id}--#{user_id}"
        tournament_id: tournament_id
        user_id: user_id
        participant_email: participant_email
    Doc.saveDoc doc, _type, _properties

#exports.save = (doc) ->
#    Doc.saveDoc doc, _type, _properties
#
#exports.fetch = (id) ->
#    Doc.fetchDoc id, _type
