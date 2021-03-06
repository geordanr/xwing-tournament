# Run this with mocha
Q = require 'q'
nano = require 'nano'
uuid = require 'node-uuid'

server = nano 'http://localhost:5984'

Doc = require '../../lib/doc'
User = require '../../lib/user'
Participant = require '../../lib/participant'
Tournament = require '../../lib/tournament'
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

    it "saves users", ->
        res = User.save make_fake_user()
        res.should.eventually.have.property 'rev'

    it "finds users based on a strategy and oauth id", ->
        user = User.save
            oauth_strategy: 'test_strat'
            oauth_id: '1234'
            email: 'test@example.com'
        .then ->
            User.find 'test_strat', '1234'

        user.should.eventually.have.property 'email', 'test@example.com'

    it "returns null for a nonexistent strategy/oauth id pair", ->
        user = User.find 'nonexistent', 'xxxx'

        user.should.eventually.be.null

    it "logs users in using all supported OAuth strategies"

    it "lets users view all tournaments"

    it "should be able to submit a list to a tournament they've entered"

    it "should be able to remove an already submitted list (if it hasn't been approved/locked)"

    it "should be able to view tournaments entered"

    it "should be able to view lists submitted to a tournament entry"

    it "should be able to view the state and outcomes of all matches in a tournament"
