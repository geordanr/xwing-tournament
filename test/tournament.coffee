# Run this with mocha
Q = require 'q'
nano = require 'nano'
uuid = require 'node-uuid'

server = nano 'http://localhost:5984'

Doc = require '../lib/doc'
Tournament = require '../lib/tournament'
{createViews} = require '../lib/designdoc'

describe "Tournament", ->

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

    it "should be able to save a new tournament", ->
        tournament =
            name: 'Test tournament'
            description: 'Tournament description is here'
            organizer_user_id: 'abc-123'
            organizer_email: 'organizer@example.com'
            event_start_timestamp: 123456789
            event_end_timestamp: 234567890

        promise = Tournament.save tournament
        Q.all [
            promise.should.eventually.have.property('id')
            promise.should.eventually.have.property('rev')
        ]

    it "should be able to load a saved tournament", ->
        tournament =
            name: 'Test tournament'
            description: 'Tournament description is here'
            organizer_user_id: 'abc-123'
            organizer_email: 'organizer@example.com'
            event_start_timestamp: 123456789
            event_end_timestamp: 234567890

        promise = Tournament.save tournament
        .then (results) ->
            Doc.fetchDoc results.id

        Q.all [
            promise.should.eventually.have.property 'name', tournament.name
            promise.should.eventually.have.property 'description', tournament.description
            promise.should.eventually.have.property 'organizer_user_id', tournament.organizer_user_id
            promise.should.eventually.have.property 'organizer_email', tournament.organizer_email
            promise.should.eventually.have.property 'event_start_timestamp', tournament.event_start_timestamp
            promise.should.eventually.have.property 'event_end_timestamp', tournament.event_end_timestamp
        ]

    it "should be able to save changes to an existing tournament", ->
        tournament =
            name: 'Test tournament'
            description: 'Tournament description is here'
            organizer_user_id: 'abc-123'
            organizer_email: 'organizer@example.com'
            event_start_timestamp: 123456789
            event_end_timestamp: 234567890

        new_tournament =
            name: 'Test tournament new'
            description: 'Tournament description is here new'
            organizer_user_id: 'xyz-890'
            organizer_email: 'new-organizer@example.com'
            event_start_timestamp: 234567890
            event_end_timestamp: 345678901

        promise = Tournament.save tournament
        .then (res) ->
            new_tournament._id = res.id
            Tournament.save new_tournament
        .then (results) ->
            Doc.fetchDoc results.id

        Q.all [
            promise.should.eventually.have.property 'name', new_tournament.name
            promise.should.eventually.have.property 'description', new_tournament.description
            promise.should.eventually.have.property 'organizer_user_id', new_tournament.organizer_user_id
            promise.should.eventually.have.property 'organizer_email', new_tournament.organizer_email
            promise.should.eventually.have.property 'event_start_timestamp', new_tournament.event_start_timestamp
            promise.should.eventually.have.property 'event_end_timestamp', new_tournament.event_end_timestamp
        ]

    it "should be able to delete a tournament"

    it "should allow browsing of all tournaments", ->
        tournament1 =
            name: 'Test tournament 1'
            description: 'First tournament description'
            organizer_user_id: 'abc-123'
            organizer_email: 'organizer@example.com'
            event_start_timestamp: 111111111
            event_end_timestamp: 222222222

        tournament2 =
            name: 'Test tournament 2'
            description: 'Second tournament description'
            organizer_user_id: 'xyz-890'
            organizer_email: 'new-organizer@example.com'
            event_start_timestamp: 333333333
            event_end_timestamp: 444444444

        t1_row =
            id: null
            key: tournament1.event_start_timestamp
            value: null

        t2_row =
            id: null
            key: tournament2.event_start_timestamp
            value: null

        promise = Q.all [
            Tournament.save tournament1
            Tournament.save tournament2
        ]
        .spread (t1_result, t2_result) ->
            t1_row.id = t1_result.id
            t2_row.id = t2_result.id
        .then ->
            Doc.view 'tournament', 'byStartTimestamp'

        Q.allSettled [
            promise.should.eventually.include t1_row
            promise.should.eventually.include t2_row
        ]
