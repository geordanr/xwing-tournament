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

describe "Regular User", ->

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

    it "adds a list to a tournament entry"

    it "removes a list from a tournament entry"

    it "shows the lists added to a tournament entry"

    it "lists the tournaments entered"
