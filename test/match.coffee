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

save_fake_match = (round=1) ->
    u1_id = null
    u2_id = null
    tournament_id = null
    match = Q.all [
        User.save make_fake_user()
        User.save make_fake_user()
        Tournament.save make_fake_tournament()
    ]
    .spread (u1_result, u2_result, tournament_result) ->
        u1_id = u1_result.id
        u2_id = u2_result.id
        tournament_id = tournament_result.id
        Q.all [
            Participant.enterTournament tournament_id, 'Dude 1', u1_id, 'participant1@example.com'
            Participant.enterTournament tournament_id, 'Dude 2', u2_id, 'participant2@example.com'
        ]
    .spread (p1_res, p2_res) ->
        Q.all [
            Participant.fetch p1_res.id
            Participant.fetch p2_res.id
        ]
    .spread (p1, p2) ->
        Q.all [
            Participant.addList p1._id, [ { pilot: "Rookie Pilot", ship: "X-Wing", upgrades: [] } ], 'http://example.com/1'
            Participant.addList p2._id, [ { pilot: "Academy Pilot", ship: "TIE Fighter", upgrades: [] } ], 'http://example.com/2'
            Q.fcall -> p1._id
            Q.fcall -> p2._id
        ]
    .spread (list1_res, list2_res, p1_id, p2_id) ->
        Match.save
            tournament_id: tournament_id
            round: round
            participants: [
                {
                    participant_id: p1_id
                    list_id: list1_res.id
                }
                {
                    participant_id: p2_id
                    list_id: list2_res.id
                }
            ]
    .then (res) ->
        Match.fetch res.id

customAwarderFunc = (participants, winner_id, result) ->
    awarded_points = {}
    for participant in participants
        switch result
            when "Match Win"
                awarded_points[participant.participant_id] = if participant.participant_id == winner_id then 5 else 0
            when "Modified Match Win"
                awarded_points[participant.participant_id] = if participant.participant_id == winner_id then 3 else 0
            when "Draw"
                awarded_points[participant.participant_id] = 1
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
        match = save_fake_match 42

        match.should.eventually.have.property 'tournament_id'
        match.should.eventually.not.have.property 'tournament_id', null
        match.should.eventually.have.property 'round', 42

    it "has the participants and lists they played", ->
        save_fake_match()
        .then (match) ->
            promises = [ match.participants.should.have.length 2 ]
            .concat (participant.should.have.keys [ 'participant_id', 'list_id' ] for participant in match.participants)

            Q.all promises

    it "has no result if the match isn't finished", ->
        match = save_fake_match 42

        Q.all [
            match.should.eventually.have.property 'finished', false
            match.should.eventually.have.property 'result', null
        ]

    it "has a result if the match is finished", ->
        winner_id = null
        save_fake_match 42
        .then (m) ->
            winner_id = m.participants[0].participant_id
            Match.finish m._id, winner_id, "Win"
        .then (res) ->
            Match.fetch res.id
        .then (match) ->
            Q.all [
                match.should.have.property 'finished', true
                match.should.have.property 'result', "Win"
                match.should.have.property 'winner', winner_id
                match.awarded_points.should.have.property match.winner, 1
            ]

    it "supports custom points for Match Wins", ->
        winner_id = null
        save_fake_match 42
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
                match.awarded_points.should.have.property match.winner, 5
            ]

    it "supports custom points for Modified Match Wins", ->
        winner_id = null
        save_fake_match 42
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
                match.awarded_points.should.have.property match.winner, 3
            ]

    it "supports custom points for Draws", ->
        winner_id = null
        save_fake_match 42
        .then (m) ->
            winner_id = m.participants[0].participant_id
            Match.finish m._id, null, "Draw", customAwarderFunc
        .then (res) ->
            Match.fetch res.id
        .then (match) ->
            Q.all [
                match.should.have.property 'finished', true
                match.should.have.property 'result', "Draw"
                match.should.have.property 'winner', null
                match.awarded_points.should.have.property match.participants[0].participant_id, 1
                match.awarded_points.should.have.property match.participants[1].participant_id, 1
            ]

    it "supports having a bye"
