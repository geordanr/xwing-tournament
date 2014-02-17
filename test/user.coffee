# Run this with mocha
Q = require 'q'
nano = require('nano') 'http://localhost:5984'
uuid = require 'node-uuid'

Doc = require '../lib/doc'
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
            createViews db
            .fail (err) ->
                console.error "Error creating CouchDB views: #{err}"
            .finally ->
                #console.log "done creating #{db.config.db}"
                done()

afterEach ->
    #console.log "Destroying #{db.config.db}"
    nano.db.destroy db.config.db

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
