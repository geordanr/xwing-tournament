# Run this with mocha
Q = require 'q'
nano = require 'nano'
uuid = require 'node-uuid'

server = nano 'http://localhost:5984'

Doc = require '../lib/doc'
User = require '../lib/user'
Participant = require '../lib/participant'
Tournament = require '../lib/tournament'
Match = require '../lib/match'
{createViews} = require '../lib/designdoc'

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

customAwarderFunc = (participants, winner_id, result) ->
    awarded_points = {}
    for participant in participants
        switch result
            when "Match Win"
                awarded_points[participant.participant_id] = if participant.participant_id == winner_id then 42 else 0
            when "Modified Match Win"
                awarded_points[participant.participant_id] = if participant.participant_id == winner_id then 69 else 0
            when "Draw"
                awarded_points[participant.participant_id] = 33
    awarded_points

describe "Match", ->

    beforeEach (done) ->
        dbname = "xwing-tournament-test-#{@currentTest.title.toLowerCase().replace /[^a-z0-9]/g, '-'}-#{uuid.v4()}"
        #console.log "Create #{dbname}"
        Q.nfcall server.db.create, dbname
        .then =>
            @db = server.use dbname
            Doc.use @db
            createViews()
        .then =>
            Q.all [
                User.save make_fake_user()
                User.save make_fake_user()
                Tournament.save make_fake_tournament()
            ]
        .spread (u1_result, u2_result, tournament_result) =>
            @user1_id = u1_result.id
            @user2_id = u2_result.id
            @tournament_id = tournament_result.id
            Q.all [
                Participant.enterTournament @tournament_id, 'Dude 1', @user1_id, 'participant1@example.com'
                Participant.enterTournament @tournament_id, 'Dude 2', @user2_id, 'participant2@example.com'
            ]
        .spread (p1_res, p2_res) =>
            @participant1_id = p1_res.id
            @participant2_id = p2_res.id
            Q.all [
                Participant.fetch @participant1_id
                Participant.fetch @participant2_id
            ]
        .then =>
            Q.all [
                Participant.addList @participant1_id, [ { pilot: "Rookie Pilot", ship: "X-Wing", upgrades: [] } ], 'http://example.com/1'
                Participant.addList @participant2_id, [ { pilot: "Academy Pilot", ship: "TIE Fighter", upgrades: [] } ], 'http://example.com/2'
            ]
        .spread (list1_res, list2_res) =>
            @list1_id = list1_res.id
            @list2_id = list2_res.id
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

    it "exists in a round in a tournament", ->
        round = 42
        match = Match.new @tournament_id, round, @list1_id, @list2_id
        .then (res) ->
            Match.fetch res.id

        match.should.eventually.have.property 'tournament_id'
        match.should.eventually.not.have.property 'tournament_id', null
        match.should.eventually.have.property 'round', round

    it "has the participants and lists they played", ->
        round = 42
        Match.new @tournament_id, round, @list1_id, @list2_id
        .then (res) ->
            Match.fetch res.id
        .then (match) ->
            promises = [ match.participants.should.have.length 2 ]
            .concat (participant.should.have.keys [ 'participant_id', 'list_id' ] for participant in match.participants)

            Q.all promises

    it "has no result if the match isn't finished", ->
        round = 42
        match = Match.new @tournament_id, round, @list1_id, @list2_id
        .then (res) ->
            Match.fetch res.id

        Q.all [
            match.should.eventually.have.property 'finished', false
            match.should.eventually.have.property 'result', null
        ]

    it "has a result if the match is finished", ->
        winner_id = null
        round = 42
        match = Match.new @tournament_id, round, @list1_id, @list2_id
        .then (res) ->
            Match.fetch res.id
        .then (m) ->
            winner_id = m.participants[0].participant_id
            Match.finish m._id, winner_id, "Match Win"
        .then (res) ->
            Match.fetch res.id
        .then (match) ->
            Q.all [
                match.should.have.property 'finished', true
                match.should.have.property 'result', "Match Win"
                match.should.have.property 'winner', winner_id
                match.awarded_points.should.have.property match.winner, 5
            ]

    it "supports custom points for Match Wins", ->
        winner_id = null
        round = 42
        match = Match.new @tournament_id, round, @list1_id, @list2_id
        .then (res) ->
            Match.fetch res.id
        .then (m) ->
            winner_id = m.participants[0].participant_id
            Match.finish m._id, winner_id, "Match Win", customAwarderFunc
        .then (res) ->
            Match.fetch res.id
        .then (match) ->
            Q.all [
                match.should.have.property 'finished', true
                match.should.have.property 'result', "Match Win"
                match.should.have.property 'winner', winner_id
                match.awarded_points.should.have.property match.winner, 42
            ]

    it "supports custom points for Modified Match Wins", ->
        winner_id = null
        round = 42
        match = Match.new @tournament_id, round, @list1_id, @list2_id
        .then (res) ->
            Match.fetch res.id
        .then (m) ->
            winner_id = m.participants[0].participant_id
            Match.finish m._id, winner_id, "Modified Match Win", customAwarderFunc
        .then (res) ->
            Match.fetch res.id
        .then (match) ->
            Q.all [
                match.should.have.property 'finished', true
                match.should.have.property 'result', "Modified Match Win"
                match.should.have.property 'winner', winner_id
                match.awarded_points.should.have.property match.winner, 69
            ]

    it "supports custom points for Draws", ->
        round = 42
        match = Match.new @tournament_id, round, @list1_id, @list2_id
        .then (res) ->
            Match.fetch res.id
        .then (m) ->
            Match.finish m._id, null, "Draw", customAwarderFunc
        .then (res) ->
            Match.fetch res.id
        .then (match) ->
            Q.all [
                match.should.have.property 'finished', true
                match.should.have.property 'result', "Draw"
                match.should.have.property 'winner', null
                match.awarded_points.should.have.property match.participants[0].participant_id, 33
                match.awarded_points.should.have.property match.participants[1].participant_id, 33
            ]

    it "supports having a bye", ->
        Match.bye @tournament_id, 42, @list1_id
        .then (res) ->
            Match.fetch res.id
        .then (match) ->
            Q.all [
                match.should.have.property 'finished', true
                match.should.have.property 'result', "Bye"
                match.should.have.property 'winner', match.participants[0].participant_id
                match.awarded_points.should.have.property match.participants[0].participant_id, 5
                match.awarded_points.should.have.property match.participants[1].participant_id, 0
            ]

    it "can be created without participants", ->
        Match.new @tournament_id, 42
        .then (res) ->
            Match.fetch res.id
        .then (match) ->
            match.participants.should.have.deep.members [
                {
                    participant_id: null
                    list_id: null
                }
                {
                    participant_id: null
                    list_id: null
                }
            ]

    it "can be created with one participant", ->
        Match.new @tournament_id, 42, @list1_id
        .then (res) ->
            Match.fetch res.id
        .then (match) =>
            match.participants.should.have.deep.members = [
                {
                    participant_id: @participant1_id
                    list_id: @list1_id
                }
                {
                    participant_id: null
                    list_id: null
                }
            ]

    it "can be created with one participant in the second slot only", ->
        Match.new @tournament_id, 42, null, @list2_id
        .then (res) ->
            Match.fetch res.id
        .then (match) =>
            match.participants.should.have.deep.members = [
                {
                    participant_id: @participant2_id
                    list_id: @list2_id
                }
                {
                    participant_id: null
                    list_id: null
                }
            ]

    it "can have participant/list pairs added to the first empty slot when both are empty", ->
        Match.new @tournament_id, 42
        .then (res) ->
            Match.fetch res.id
        .then (match) =>
            Match.addList match._id, @list1_id
        .then (res) ->
            Match.fetch res.id
        .then (match) =>
            match.participants.should.have.deep.members [
                {
                    participant_id: @participant1_id
                    list_id: @list1_id
                }
                {
                    participant_id: null
                    list_id: null
                }
            ]

    it "can have participant/list pairs added to the first empty slot it is empty", ->
        Match.new @tournament_id, 42, null, @list2_id
        .then (res) ->
            Match.fetch res.id
        .then (match) =>
            Match.addList match._id, @list1_id
        .then (res) ->
            Match.fetch res.id
        .then (match) =>
            match.participants.should.have.deep.members [
                {
                    participant_id: @participant1_id
                    list_id: @list1_id
                }
                {
                    participant_id: @participant2_id
                    list_id: @list2_id
                }
            ]

    it "can have participant/list pairs added to the second empty slot when it is empty", ->
        Match.new @tournament_id, 42, @list1_id
        .then (res) ->
            Match.fetch res.id
        .then (match) =>
            Match.addList match._id, @list2_id
        .then (res) ->
            Match.fetch res.id
        .then (match) =>
            match.participants.should.have.deep.members [
                {
                    participant_id: @participant1_id
                    list_id: @list1_id
                }
                {
                    participant_id: @participant2_id
                    list_id: @list2_id
                }
            ]

    it "should not allow adding lists to Byes", ->
        match = Match.bye @tournament_id, 42, @list1_id
        .then (res) ->
            Match.addList res.id, @list2_id

        match.should.eventually.be.rejectedWith Error

    it "should not allow adding lists to finished matches", ->
        match = Match.new @tournament_id, 42, @list1_id
        .then (res) =>
            Match.finish res._id, @participant1_id, "Match Win"
        .then (res) =>
            Match.addList res.id, @list2_id

        match.should.eventually.be.rejectedWith Error
