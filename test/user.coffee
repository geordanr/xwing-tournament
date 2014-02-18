# Run this with mocha
Q = require 'q'
nano = require('nano') 'http://localhost:5984'
uuid = require 'node-uuid'

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
        dbname = "xwing-tournament-test-#{uuid.v4()}"
        #console.log "Create #{dbname}"
        nano.db.create dbname, (err, body) =>
            if err
                throw new Error "Error creating database #{dbname}: #{err}"
            else
                #console.log "Created #{dbname}"
                @db = nano.use dbname
                Doc.use @db
                createViews()
                .fail (err) =>
                    throw new Error "Error creating CouchDB views: #{err}"
                .finally =>
                    #console.log "done creating #{@db.config.db}"
                    done()

    afterEach ->
        #console.log "Destroying #{@db.config.db}"
        nano.db.destroy @db.config.db

    it "should be able to log in using all supported OAuth strategies"

    it "should be able to view all tournaments"

    it "should be able to enter a tournament exactly once", ->
        tournament_id = null
        promise = Q.all [
            User.save make_fake_user()
            Tournament.save make_fake_tournament()
        ]
        .spread (user_result, tournament_result) ->
            tournament_id = tournament_result.id
            Participant.enterTournament tournament_id, user_result.id, 'participant@example.com'
        .then (res) ->
            Doc.view 'tournament', 'participantsByTournament'#, {key: tournament_id}
        .then (rows) ->
            console.dir rows
            rows
        .fail (err) ->
            throw new Error err

    it "should be able to submit a list to a tournament they've entered"

    it "should be able to remove an already submitted list (if it hasn't been approved/locked)"

    it "should be able to view tournaments entered"

    it "should be able to view lists submitted to a tournament entry"

    it "should be able to view the state and outcomes of all matches in a tournament"
