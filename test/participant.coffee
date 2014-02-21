# Run this with mocha
Q = require 'q'
nano = require 'nano'
uuid = require 'node-uuid'

server = nano 'http://localhost:5984'

Doc = require '../lib/doc'
User = require '../lib/user'
Participant = require '../lib/participant'
Tournament = require '../lib/tournament'
{createViews} = require '../lib/designdoc'

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

describe "Participant", ->

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

    it "lets a user enter a tournament", ->
        user_id = null
        tournament_id = null
        entered = Q.all [
            User.save make_fake_user()
            Tournament.save make_fake_tournament()
        ]
        .spread (user_result, tournament_result) ->
            user_id = user_result.id
            tournament_id = tournament_result.id
            Participant.enterTournament tournament_id, user_id, 'participant@example.com'
        .then ->
            Participant.checkIfEntryExists tournament_id, user_id

        entered.should.become true

    it "allows a user to enter a tournament exactly once", ->
        user_id = null
        tournament_id = null
        rows = Q.all [
            User.save make_fake_user()
            Tournament.save make_fake_tournament()
        ]
        .spread (user_result, tournament_result) ->
            user_id = user_result.id
            tournament_id = tournament_result.id
        .then ->
            Participant.enterTournament tournament_id, user_id, 'participant@example.com'
        .then ->
            Participant.enterTournament tournament_id, user_id, 'participant@example.com'

        rows.should.eventually.be.rejectedWith Error

    it "revokes an entry into a tournament", ->
        user_id = null
        tournament_id = null
        entered = Q.all [
            User.save make_fake_user()
            Tournament.save make_fake_tournament()
        ]
        .spread (user_result, tournament_result) ->
            user_id = user_result.id
            tournament_id = tournament_result.id
            Participant.enterTournament tournament_id, user_id, 'participant@example.com'
        .then ->
            Participant.revokeEntry tournament_id, user_id
        .then ->
            Participant.checkIfEntryExists tournament_id, user_id

        entered.should.become false

    it "adds a list to a tournament entry", ->
        user_id = null
        tournament_id = null
        rows = Q.all [
            User.save make_fake_user()
            Tournament.save make_fake_tournament()
        ]
        .spread (user_result, tournament_result) ->
            user_id = user_result.id
            tournament_id = tournament_result.id
        .then ->
            Participant.enterTournament tournament_id, user_id, 'participant@example.com'
        .then (res) ->
            ships = [
                {
                    pilot: "Rookie Pilot"
                    ship: "X-Wing"
                    upgrades: []
                }
                {
                    pilot: "Gold Squadron Pilot"
                    ship: "Y-Wing"
                    upgrades: []
                }
                {
                    pilot: "Rookie Pilot"
                    ship: "X-Wing"
                    upgrades: []
                }
            ]
            url = "http://example.com/"
            Participant.addList res.id, ships, url

    it "removes a list from a tournament entry"

    it "shows the lists added to a tournament entry", ->
        user_id = null
        tournament_id = null
        lists = Q.all [
            User.save make_fake_user()
            Tournament.save make_fake_tournament()
        ]
        .spread (user_result, tournament_result) ->
            user_id = user_result.id
            tournament_id = tournament_result.id
        .then ->
            Participant.enterTournament tournament_id, user_id, 'participant@example.com'
        .then (res) ->
            ships = [
                {
                    pilot: "Rookie Pilot"
                    ship: "X-Wing"
                    upgrades: []
                }
                {
                    pilot: "Gold Squadron Pilot"
                    ship: "Y-Wing"
                    upgrades: []
                }
                {
                    pilot: "Rookie Pilot"
                    ship: "X-Wing"
                    upgrades: []
                }
            ]
            url = "http://example.com/"
            Participant.addList res.id, ships, url
            res.id
        .then (participant_id) ->
            ships = [
                {
                    pilot: "Avenger Squadron Pilot"
                    ship: "TIE Interceptor"
                    upgrades: []
                }
                {
                    pilot: "Academy Pilot"
                    ship: "TIE Fighter"
                    upgrades: []
                }
            ]
            url = "http://example.com/"
            Participant.addList participant_id, ships, url
            participant_id
        .then (participant_id) ->
            Participant.getLists participant_id

        expected = [
            {
                ships: '2x X-Wing, 1x Y-Wing'
                url: 'http://example.com/'
            }
            {
                ships: '1x TIE Fighter, 1x TIE Interceptor',
                url: 'http://example.com/'
            }
        ]

        lists.should.eventually.have.deep.members expected

    it "lists the tournaments entered", ->
        user_id = null
        t1_id = null
        t2_id = null
        t3_id = null

        promise = Q.all [
            User.save make_fake_user()
            Tournament.save make_fake_tournament()
            Tournament.save make_fake_tournament()
            Tournament.save make_fake_tournament()
        ]
        .spread (user_res, t1_res, t2_res, t3_res) ->
            user_id = user_res.id
            t1_id = t1_res.id
            t2_id = t2_res.id
            t3_id = t3_res.id

            Q.all [
                Participant.enterTournament t1_id, user_id
                Participant.enterTournament t2_id, user_id
            ]
        .then ->
            Q.all [
                Participant.checkIfEntryExists t1_id, user_id
                Participant.checkIfEntryExists t2_id, user_id
                Participant.checkIfEntryExists t3_id, user_id
            ]
        .spread (t1_entered, t2_entered, t3_entered) ->
            [ t1_entered, t2_entered, t3_entered ]

        promise.should.become [true, true, false]
