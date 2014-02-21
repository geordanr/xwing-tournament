Q = require 'q'
Doc = require './doc'

_type = 'list'
_properties = [
    "tournament_id"
    "participant_id"
    "ships"
    "url"
    "approved"
]

#ships: [
#    {
#        pilot: "Wedge Antilles"
#        ship: "X-Wing"
#        upgrades: [
#            "Expose"
#            "R2 Astromech"
#        ]
#    }
#    ...
#]

exports.save = (doc) ->
    # validate ships
    try
        for ship in doc.ships
            throw new Error "Pilot required" unless ship.pilot?
            throw new Error "Ship reqiured" unless ship.ship?
            throw new Error "Upgrades required" unless ship.upgrades? and ship.upgrades instanceof Array
        Doc.saveDoc doc, _type, _properties
    catch err
        Q.fcall ->
            throw err

exports.fetch = (id) ->
    Doc.fetchDoc id, _type
