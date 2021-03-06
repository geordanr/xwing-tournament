# Run this with mocha
Q = require 'q'
nano = require 'nano'
uuid = require 'node-uuid'

server = nano 'http://localhost:5984'

Doc = require '../../lib/doc'
Match = require '../../lib/match'
Participant = require '../../lib/participant'
Tournament = require '../../lib/tournament'
User = require '../../lib/user'
{createViews} = require '../../lib/designdoc'

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

tournament_properties = [
    'name'
    'description'
    'organizer_user_id'
    'organizer_email'
    'event_start_timestamp'
    'event_end_timestamp'
]

describe "Tournament", ->

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

    it "saves a new tournament", ->
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

    it "loads a saved tournament", ->
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

        Q.all(promise.should.eventually.have.property(property, tournament[property]) for property in tournament_properties)

    it "saves changes to an existing tournament", ->
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
        .then (res) ->
            new_tournament._id = res.id
            Tournament.save new_tournament
        .then (results) ->
            Doc.fetchDoc results.id

        Q.all(promise.should.eventually.have.property(property, new_tournament[property]) for property in tournament_properties)

    it "deletes a tournament"

    it "lists tournaments", ->
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
            Tournament.getAll 0

        Q.allSettled [
            promise.should.eventually.include t1_row
            promise.should.eventually.include t2_row
        ]

    it "lists tournaments after a given time", ->
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
            Tournament.getAll 222222222

        Q.allSettled [
            promise.should.eventually.not.include t1_row
            promise.should.eventually.include t2_row
        ]

    it "lists tournaments after now", ->
        now = parseInt((new Date()).getTime() / 1000)
        tournament1 =
            name: 'Test tournament 1'
            description: 'First tournament description'
            organizer_user_id: 'abc-123'
            organizer_email: 'organizer@example.com'
            event_start_timestamp: now - 86400
            event_end_timestamp: now - 80000

        tournament2 =
            name: 'Test tournament 2'
            description: 'Second tournament description'
            organizer_user_id: 'xyz-890'
            organizer_email: 'new-organizer@example.com'
            event_start_timestamp: now + 86400
            event_end_timestamp: now + 96400

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
            Tournament.getAll

        Q.allSettled [
            promise.should.eventually.not.include t1_row
            promise.should.eventually.include t2_row
        ]

    it "lists the participants", ->
        u1_id = null
        u2_id = null
        tournament_id = null
        Q.all [
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
                Tournament.getParticipants tournament_id
                Participant.fetch p1_res.id
                Participant.fetch p2_res.id
            ]
        .spread (participants, p1, p2) ->
            participants.should.have.deep.members [p1, p2]

    it "lists the rounds", ->
        tournament_id = null
        user_ids = null
        participant_ids = null
        list_ids = null
        match_ids = null

        n_users = 4
        n_lists_per_participant = 1
        n_matches = 3

        rounds = Tournament.save make_fake_tournament()
        .then (res) ->
            tournament_id = res.id
            Q.all(User.save(make_fake_user()) for _ in [1..n_users])
        .spread (user_results...) ->
            user_ids = (res.id for res in user_results)
            Q.all(Participant.enterTournament(tournament_id, "Entrant #{i}", user_ids[i-1], "participant#{i}@example.com") for i in [1..n_users])
        .spread (participant_results...) ->
            participant_ids = (res.id for res in participant_results)
            Q.all(Participant.addList(participant_ids[i-1], [ { pilot: "Rookie Pilot", ship: "X-Wing", upgrades: [] } ], "http://example.com/#{i}") for i in [1..participant_ids.length])
        .spread (list_results...) ->
            list_ids = (res.id for res in list_results)
            Q.all [
                Match.new tournament_id, 1, list_ids[0], list_ids[1]
                Match.new tournament_id, 1, list_ids[2], list_ids[3]
                Match.new tournament_id, 2, list_ids[0], list_ids[3]
            ]
        .then ->
            Tournament.getRounds tournament_id

        rounds.should.eventually.have.members [1, 2]

    it "lists the matches in a round", ->
        tournament_id = null
        user_ids = null
        participant_ids = null
        list_ids = null
        match_ids = null

        n_users = 4
        n_lists_per_participant = 1
        n_matches = 3

        rounds = Tournament.save make_fake_tournament()
        .then (res) ->
            tournament_id = res.id
            Q.all(User.save(make_fake_user()) for _ in [1..n_users])
        .spread (user_results...) ->
            user_ids = (res.id for res in user_results)
            Q.all(Participant.enterTournament(tournament_id, "Entrant #{i}", user_ids[i-1], "participant#{i}@example.com") for i in [1..n_users])
        .spread (participant_results...) ->
            participant_ids = (res.id for res in participant_results)
            Q.all(Participant.addList(participant_ids[i-1], [ { pilot: "Rookie Pilot", ship: "X-Wing", upgrades: [] } ], "http://example.com/#{i}") for i in [1..participant_ids.length])
        .spread (list_results...) ->
            list_ids = (res.id for res in list_results)
            Q.all [
                Match.new tournament_id, 1, list_ids[0], list_ids[1]
                Match.new tournament_id, 1, list_ids[2], list_ids[3]
                Match.new tournament_id, 2, list_ids[0], list_ids[3]
            ]
        .spread (match_results...) ->
            Q.all(Match.fetch(res.id) for res in match_results)
        .spread (matches...) ->
            Q.all [
                Tournament.getMatches tournament_id, 1
                Tournament.getMatches tournament_id, 2
                Q.fcall -> matches
            ]
        .spread (round1_matches, round2_matches, expected) ->
            Q.all [
                round1_matches.should.have.deep.members [ expected[0], expected[1] ]
                round2_matches.should.have.deep.members [ expected[2] ]
            ]

    it "cannot end before it starts", ->
        now = parseInt((new Date()).getTime() / 1000)
        tournament = Tournament.save
            name: 'Test tournament 1'
            description: 'First tournament description'
            organizer_user_id: 'abc-123'
            organizer_email: 'organizer@example.com'
            event_start_timestamp: now
            event_end_timestamp: now - 1

        tournament.should.be.rejectedWith Error

