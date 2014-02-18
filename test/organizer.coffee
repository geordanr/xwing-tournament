# Run this with mocha
Q = require 'q'
nano = require('nano') 'http://localhost:5984'
uuid = require 'node-uuid'

Doc = require '../lib/doc'
{createViews} = require '../lib/designdoc'

describe "Tournament Organizer", ->

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
                    console.error "Error creating CouchDB views: #{err}"
                .finally =>
                    #console.log "done creating #{db.config.db}"
                    done()

    afterEach ->
        #console.log "Destroying #{db.config.db}"
        nano.db.destroy @db.config.db

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
