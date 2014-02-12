# Run this with mocha
assert = require 'assert'
should = require 'should'
nano = require('nano') 'http://localhost:5984'
uuid = require 'node-uuid'

{Tournament} = require '../lib/tournament'

dbname = null
db = null

describe "X-Wing Tournament Helper", ->
    before (done) ->
        dbname = "xwing-tournament-test-#{uuid.v4()}"
        nano.db.create dbname, ->
            db = nano.use dbname
            done()

    after (done) ->
        nano.db.destroy dbname, ->
            done()

    describe "Tournament", ->
        it "should be able to create a new tournament", ->
            args =
                name: 'Test tournament'
                description: 'Tournament description is here'
                organizer_user_id: 'abc-123'
                organizer_email: 'organizer@example.com'

            tournament = new Tournament args

            tournament.should.have.a.property 'data'
            for key, value of args
                tournament.data.should.have.a.property key, value

        it "should be able to save and load a new tournament", (done) ->
            args =
                name: 'Test tournament'
                description: 'Tournament description is here'
                organizer_user_id: 'abc-123'
                organizer_email: 'organizer@example.com'

            tournament = new Tournament args
            tournament_id = tournament._id
            do (args) ->
                tournament.saveTo db, ->
                    Tournament.fetch db, tournament_id, (t) ->
                        t.should.have.a.property 'data'
                        for key, value of args
                            tournament.data.should.have.a.property key, value
                        done()

        it "should be able to save changes to an existing tournament", (done) ->
            args =
                name: 'Test tournament'
                description: 'Tournament description is here'
                organizer_user_id: 'abc-123'
                organizer_email: 'organizer@example.com'

            new_args =
                name: 'Test tournament new'
                description: 'Tournament description is here new'
                organizer_user_id: 'xyz-890'
                organizer_email: 'new-organizer@example.com'

            tournament = new Tournament args
            tournament_id = tournament._id
            do (args, new_args) ->
                tournament.saveTo db, ->
                    Tournament.fetch db, tournament_id, (t) ->
                        for k, v of new_args
                            t.data[k] = v
                        t.saveTo db, ->
                            Tournament.fetch db, tournament_id, (updated_t) ->
                                for k, v of new_args
                                    t.data.should.have.a.property k, v
                                done()

        it "should be able to delete a tournament", ->
            assert false, 'not implemented'

    describe "Regular User", ->
        it "should not be considered a Tournament Organizer", ->
            assert false, 'not implemented'

        it "should be able to log in using all supported OAuth strategies", ->
            assert false, 'not implemented'

        it "should be able to view all tournaments", ->
            assert false, 'not implemented'

        it "should be not able to tournaments they don't own", ->
            assert false, 'not implemented'

        it "should be able to enter a tournament", ->
            assert false, 'not implemented'

        it "should be able to submit a list", ->
            assert false, 'not implemented'

        it "should be able to remove an already submitted list (if it hasn't been approved/locked)", ->
            assert false, 'not implemented'

        it "should be able to view tournaments entered", ->
            assert false, 'not implemented'

        it "should be able to view lists submitted to a tournament entry", ->
            assert false, 'not implemented'

        it "should be able to view the state and outcomes of all matches", ->
            assert false, 'not implemented'

    describe "Tournament Organizer", ->
        it "should be considered a Regular User", ->
            assert false, 'not implemented'

        it "should be able to create a new tournament", ->
            assert false, 'not implemented'

        it "should be able to edit details for a tournament they own", ->
            assert false, 'not implemented'

        it "should not be able to edit details for a tournament they don't own", ->
            assert false, 'not implemented'

        it "should be able to delete a tournament they own", ->
            assert false, 'not implemented'

        it "should not be able to delete a tournament they don't own", ->
            assert false, 'not implemented'

        it "should be able to approve entries to the tournament", ->
            assert false, 'not implemented'

        it "should be able to approve lists submitted to the tournament", ->
            assert false, 'not implemented'

        it "should be able to create a new round of matches", ->
            assert false, 'not implemented'

        it "should be able to pair participants into matches for a round", ->
            assert false, 'not implemented'

        it "should be able to set the outcome of a match", ->
            assert false, 'not implemented'
