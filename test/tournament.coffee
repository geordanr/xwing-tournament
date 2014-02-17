# Run this with mocha
Q = require 'q'
nano = require('nano') 'http://localhost:5984'
uuid = require 'node-uuid'

Doc = require '../lib/doc'
Tournament = require '../lib/tournament'
{createViews} = require '../lib/designdoc'

db = null

beforeEach (done) ->
    dbname = "xwing-tournament-test-#{uuid.v4()}"
    #console.log "Create #{dbname}"
    nano.db.create dbname, (err, body) ->
        if err
            throw new Error "Error creating database #{dbname}: #{err}"
        else
            #console.log "Created #{dbname}"
            db = nano.use dbname
            #console.log "Now using #{db.config.db}"
            Doc.use db
            Tournament.use db
            createViews db
            .fail (err) ->
                console.error "Error creating CouchDB views: #{err}"
            .finally ->
                #console.log "done creating #{db.config.db}"
                done()

afterEach ->
    #console.log "Destroying #{db.config.db}"
    nano.db.destroy db.config.db

describe "Tournament", ->
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
        promise.then (tournament) ->
            for own key, val of new_tournament
                tournament[key] = val
            Tournament.save tournament
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
            Doc.view 'tournament', 'tournamentsByStart'

        Q.allSettled [
            promise.should.eventually.include t1_row
            promise.should.eventually.include t2_row
        ]
