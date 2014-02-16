# Run this with mocha
require('mocha-as-promised')()
Q = require 'q'
assert = require 'assert'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'
should = require('chai').should()
nano = require('nano') 'http://localhost:5984'
uuid = require 'node-uuid'

chai.use chaiAsPromised

{Doc} = require '../lib/doc'
{Tournament} = require '../lib/tournament'
{createViews} = require '../lib/designdoc'

dbname = null
db = null

describe "X-Wing Tournament Helper", ->
    beforeEach (done) ->
        dbname = "xwing-tournament-test-#{uuid.v4()}"
        nano.db.create dbname, ->
            db = nano.use dbname
            done()

    afterEach ->
        nano.db.destroy dbname

    describe "CouchDB Views", ->
        it "should imprint views", ->
            promise = createViews db
            promise.should.eventually.have.property 'id', '_design/tournament'
            promise.should.eventually.have.property 'rev'

        it "should imprint views over old ones", ->
            first_rev = null
            promise = createViews db
            .then (results) ->
                first_rev = results.rev
                createViews db
            promise.should.eventually.have.property 'id', '_design/tournament'
            promise.should.eventually.not.have.property 'rev', first_rev

    describe "Tournament", ->
        it "should be able to save a new tournament", ->
            tournament =
                name: 'Test tournament'
                description: 'Tournament description is here'
                organizer_user_id: 'abc-123'
                organizer_email: 'organizer@example.com'

            promise = Tournament.save db, tournament
            Q.all [
                promise.should.eventually.have.property 'id'
                promise.should.eventually.have.property 'rev'
            ]

        it "should be able to load a saved tournament", ->
            tournament =
                name: 'Test tournament'
                description: 'Tournament description is here'
                organizer_user_id: 'abc-123'
                organizer_email: 'organizer@example.com'

            promise = Tournament.save db, tournament
            .then (results) ->
                Doc.fetchDoc db, results.id

            Q.all [
                promise.should.eventually.have.property 'name', tournament.name
                promise.should.eventually.have.property 'description', tournament.description
                promise.should.eventually.have.property 'organizer_user_id', tournament.organizer_user_id
                promise.should.eventually.have.property 'organizer_email', tournament.organizer_email
            ]

        it "should be able to save changes to an existing tournament", ->
            tournament =
                name: 'Test tournament'
                description: 'Tournament description is here'
                organizer_user_id: 'abc-123'
                organizer_email: 'organizer@example.com'

            new_tournament =
                name: 'Test tournament new'
                description: 'Tournament description is here new'
                organizer_user_id: 'xyz-890'
                organizer_email: 'new-organizer@example.com'

            promise = Tournament.save db, tournament
            promise.then (tournament) ->
                for own key, val of new_tournament
                    tournament[key] = val
                Tournament.save db, tournament
            .then (results) ->
                Doc.fetchDoc db, results.id

            Q.all [
                promise.should.eventually.have.property 'name', new_tournament.name
                promise.should.eventually.have.property 'description', new_tournament.description
                promise.should.eventually.have.property 'organizer_user_id', new_tournament.organizer_user_id
                promise.should.eventually.have.property 'organizer_email', new_tournament.organizer_email
            ]

        it "should be able to delete a tournament"

    describe "Regular User", ->
        it "should not be considered a Tournament Organizer"

        it "should be able to log in using all supported OAuth strategies"

        it "should be able to view all tournaments"

        it "should be not able to tournaments they don't own"

        it "should be able to enter a tournament"

        it "should be able to submit a list"

        it "should be able to remove an already submitted list (if it hasn't been approved/locked)"

        it "should be able to view tournaments entered"

        it "should be able to view lists submitted to a tournament entry"

        it "should be able to view the state and outcomes of all matches"

    describe "Tournament Organizer", ->
        it "should be considered a Regular User"

        it "should be able to create a new tournament"

        it "should be able to edit details for a tournament they own"

        it "should not be able to edit details for a tournament they don't own"

        it "should be able to delete a tournament they own"

        it "should not be able to delete a tournament they don't own"

        it "should be able to approve entries to the tournament"

        it "should be able to approve lists submitted to the tournament"

        it "should be able to create a new round of matches"

        it "should be able to pair participants into matches for a round"

        it "should be able to set the outcome of a match"
