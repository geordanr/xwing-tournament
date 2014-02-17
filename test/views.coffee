# Run this with mocha
Q = require 'q'
nano = require('nano') 'http://localhost:5984'
uuid = require 'node-uuid'

Doc = require '../lib/doc'
{createViews} = require '../lib/designdoc'

db = null

beforeEach (done) ->
    dbname = "xwing-tournament-test-#{uuid.v4()}"
    nano.db.create dbname, (err, body) ->
        if err
            throw new Error "Error creating #{dbname}: #{err}"
        db = nano.use dbname
        Doc.use db
        done()

afterEach ->
    #console.log "Destroying #{db.config.db}"
    nano.db.destroy db.config.db

describe "CouchDB Views", ->
    it.skip "should imprint views", ->
        promise = createViews db
        .then (results) ->
            Q.all [
                Doc.view('tournament', 'listsByTournamentParticipant').should.eventually.be.empty
                Doc.view('tournament', 'matchByTournamentRound').should.eventually.be.empty
                Doc.view('tournament', 'participantsByTournament').should.eventually.be.empty
            ]

    it "should imprint views over old ones", ->
        first_rev = null
        promise = createViews db
        .then (results) ->
            first_rev = results.rev
            createViews db
        .then (results) ->
            results
        promise.should.eventually.have.property 'id', '_design/tournament'
        promise.should.eventually.not.have.property 'rev', first_rev
