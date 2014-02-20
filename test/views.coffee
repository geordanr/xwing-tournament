# Run this with mocha
Q = require 'q'
nano = require 'nano'
uuid = require 'node-uuid'

server = nano 'http://localhost:5984'

Doc = require '../lib/doc'
{createViews} = require '../lib/designdoc'

describe "CouchDB Views", ->

    beforeEach (done) ->
        dbname = "xwing-tournament-test-#{@currentTest.title.toLowerCase().replace /[^a-z0-9]/g, '-'}-#{uuid.v4()}"
        #console.log "Create #{dbname}"
        Q.nfcall server.db.create, dbname
        .then =>
            @db = server.use dbname
            Doc.use @db
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

    it "should imprint views", ->
        promise = createViews()
        .then (results) ->
            Q.all [
                Doc.view('tournament', 'listsByTournamentParticipant').should.eventually.be.empty
                Doc.view('tournament', 'matchByTournamentRound').should.eventually.be.empty
                Doc.view('tournament', 'participantsByTournament').should.eventually.be.empty
            ]

    it "should imprint views over old ones", ->
        first_rev = null
        promise = createViews()
        .then (results) ->
            first_rev = results.rev
            createViews()
        .then (results) ->
            results
        promise.should.eventually.have.property 'id', '_design/tournament'
        promise.should.eventually.not.have.property 'rev', first_rev
