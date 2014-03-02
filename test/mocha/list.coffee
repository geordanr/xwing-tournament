# Run this with mocha
Q = require 'q'
nano = require 'nano'
uuid = require 'node-uuid'

server = nano 'http://localhost:5984'

Doc = require '../../lib/doc'
User = require '../../lib/user'
Participant = require '../../lib/participant'
Tournament = require '../../lib/tournament'
List = require '../../lib/list'
{createViews} = require '../../lib/designdoc'

make_fake_user = ->
    oauth_strategy: 'google'
    oauth_id: uuid.v4()

make_fake_tournament = ->
    name: "Test tournament #{uuid.v4()}"
    description: 'Fake tournament'
    organizer_user_id: 'abc-123'
    organizer_email: 'organizer@example.com'
    event_start_timestamp: parseInt(new Date().getTime() / 1000)
    event_end_timestamp: parseInt(new Date().getTime() / 1000) + 3600

make_fake_list = ->
    tournament_id: null
    participant_id: null
    ships: [
        {
            pilot: "Wedge Antilles"
            ship: "X-Wing"
            upgrades: [
                "Expose"
                "R2 Astromech"
            ]
        }
        {
            pilot: "Ten Nunb"
            ship: "B-Wing"
            upgrades: [
                "Push the Limit"
            ]
        }
        {
            pilot: "Biggs Darklighter"
            ship: "X-Wing"
            upgrades: [
                "R2-F2"
            ]
        }
    ]
    url: "http://geordanr.github.io/xwing/"
    approved: null

save_fake_list = (approved=false) ->
    Q.all [
        User.save make_fake_user()
        Tournament.save make_fake_tournament()
    ]
    .spread (user_res, tournament_res) ->
        do (user_res, tournament_res) ->
            Q.all [
                Participant.enterTournament tournament_res.id, user_res.id
                Q.fcall ->
                    tournament_res.id
            ]
    .spread (participant_res, tournament_id) ->
        ls = make_fake_list()
        ls.tournament_id = tournament_id
        ls.participant_id = participant_res.id
        ls.approved = approved
        List.save ls

describe "List", ->

    beforeEach (done) ->
        dbname = "xwing-tournament-test-#{@currentTest.title.toLowerCase().replace /[^a-z0-9]/g, '-'}-#{uuid.v4()}"
        #console.log "Create #{dbname}"
        Q.nfcall server.db.create, dbname
        .then =>
            @db = server.use dbname
            Doc.use @db
            createViews()
        .fail (err) =>
            console.error "Error creating db #{dbname}: #{err}"
            throw err
        .finally =>
            done()

    afterEach (done) ->
        #console.log "Destroying #{@db.config.db}"
        Q.nfcall server.db.destroy, @db.config.db
        #.then =>
        #    console.log "Destroyed #{@db.config.db}"
        .fail (err) =>
            console.error "Error destroying db #{@db.config.db}: #{err}"
            throw err
        .finally ->
            done()

    it "is linked to a tournament", ->
        list = save_fake_list()
        .then (res) ->
            List.fetch res.id

        Q.all [
            list.should.eventually.have.property 'tournament_id'
            list.should.eventually.not.have.property 'tournament_id', null
        ]

    it "is linked to a participant", ->
        list = save_fake_list()
        .then (res) ->
            List.fetch res.id

        Q.all [
            list.should.eventually.have.property 'participant_id'
            list.should.eventually.not.have.property 'participant_id', null
        ]

    it "has a list of ships", ->
        list = save_fake_list()
        .then (res) ->
            List.fetch res.id

        Q.all [
            list.should.eventually.have.property 'ships'
            list.should.eventually.not.have.property 'ships', null
        ]

    it "only accepts ships with a pilot", ->
        list = save_fake_list()
        .then (res) ->
            List.fetch res.id
        .then (ls) ->
            delete ls.ships[0].pilot
            List.save ls
        list.should.eventually.be.rejectedWith Error

    it "only accepts ships with a ship", ->
        list = save_fake_list()
        .then (res) ->
            List.fetch res.id
        .then (ls) ->
            delete ls.ships[0].ship
            List.save ls
        list.should.eventually.be.rejectedWith Error

    it "only accepts ships with a list of upgrades", ->
        list = save_fake_list()
        .then (res) ->
            List.fetch res.id
        .then (ls) ->
            delete ls.ships[0].upgrades
            List.save ls
        list.should.eventually.be.rejectedWith Error

    it "accepts ships with an empty list of upgrades", ->
        list = save_fake_list()
        .then (res) ->
            List.fetch res.id
        .then (ls) ->
            ls.ships[0].upgrades = []
            List.save ls
        list.should.eventually.be.fulfilled

    it "has a link to a squad builder", ->
        list = save_fake_list()
        .then (res) ->
            List.fetch res.id

        Q.all [
            list.should.eventually.have.property 'url'
            list.should.eventually.not.have.property 'url', null
        ]

    it "can be marked as approved", ->
        list = save_fake_list false
        .then (res) ->
            List.fetch res.id
        .then (l) ->
            l.approved = true
            List.save l
        .then (res) ->
            List.fetch res.id

        list.should.eventually.have.property 'approved', true

    it "can be marked as not approved", ->
        list = save_fake_list true
        .then (res) ->
            List.fetch res.id
        .then (l) ->
            l.approved = false
            List.save l
        .then (res) ->
            List.fetch res.id

        list.should.eventually.have.property 'approved', false
