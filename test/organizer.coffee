# Run this with mocha
Q = require 'q'
nano = require 'nano'
uuid = require 'node-uuid'

server = nano 'http://localhost:5984'

Doc = require '../lib/doc'
{createViews} = require '../lib/designdoc'

describe "Tournament Organizer", ->

    beforeEach (done) ->
        dbname = "xwing-tournament-test-#{uuid.v4()}"
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
        Q.nfcall server.db.destroy, @db.config.db
        .fail (err) =>
            console.error "Error destrying db #{@db.config.db}: #{err}"
            throw err
        .finally ->
            done()

    it "should be able to create a new tournament"

    it "should be the organizer for a tournament they created"

    it "should be able to edit details for a tournament they own"

    it "should not be able to edit details for a tournament they don't own"

    it "should be able to delete a tournament they own"

    it "should not be able to delete a tournament they don't own"

    it "should be able to approve entries to a tournament they own"

    it "should not be able to approve entries to a tournament they don't own"

    it "should be able to approve lists submitted to a tournament they own"

    it "should not be able to approve lists submitted to a tournament they don't own"

    it "should be able to create a new round of matches in a tournament they own"

    it "should not be able to create a new round of matches in a tournament they don't own"

    it "should be able to pair participants into matches for a round in a tournament they own"

    it "shouldn't be able to pair participants into matches for a round in a tournament they don't own"

    it "should be able to set the outcome of a match in a tournament they own"

    it "should not be able to set the outcome of a match in a tournament they don't own"
