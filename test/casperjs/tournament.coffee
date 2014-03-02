{spawn} = require 'child_process'
uuid = require 'node-uuid'

express_proc = null
dbname = "http://localhost:5984/xwing-tournament-test-server-#{uuid.v4()}"

SERVER_STARTUP_MSEC = 1500
URL_ROOT = 'http://localhost:3000'

casper.test.setUp ->
    express_proc = spawn 'env', [ "COUCHDB_URL=#{dbname}", 'coffee', 'server.coffee' ]
    express_proc.stdout.on 'data', (data) ->
        casper.log "Server: #{data}", 'debug'
    express_proc.stderr.on 'data', (data) ->
        casper.log "Server: #{data}", 'warning'
    spawn 'curl', [ '-X', 'PUT', dbname ]

casper.test.tearDown ->
    express_proc.kill()
    spawn 'curl', [ '-X', 'DELETE', dbname ]

casper.test.begin 'Functional test', (test) ->
    casper.start()

    .then ->
        @wait SERVER_STARTUP_MSEC

    .thenOpen "#{URL_ROOT}/login", ->
        @fill 'form',
            username: 'nonexistent'
            password: 'wrongpassword'
        , true

    .then ->
        test.assertUrlMatch /login$/, 'Redirects unauthenticated users back to login page'

    .thenOpen "#{dbname}/user-1",
        method: 'put'
        data: JSON.stringify
            type: 'user'
            oauth_strategy: 'google'
            oauth_id: '1234'
            email: 'google1234@example.com'

    .thenOpen "#{URL_ROOT}/login", ->
        @fill 'form',
            username: '1234'
            password: 'google'
        , true

    .then ->
        test.assertTextExists 'google1234@example.com', 'Authenticated user is redirected to protected page'

    .thenOpen "#{URL_ROOT}/api/tournaments",
        method: 'get'
        headers:
            Accept: 'application/json'
    , ->
        parsedContent = JSON.parse @getPageContent()
        test.assertEquals parsedContent, {tournaments: []}, "API returns empty list when there are no tournaments"

    .thenOpen "#{URL_ROOT}/api/tournament",
        method: 'post'
        headers:
            Accept: 'application/json'
        data:
            _method: 'PUT'
            name: 'Test tournament'
            event_start_timestamp: 1000
            event_end_timestamp: 2000
            description: "Tournament description"
    , ->
        parsedContent = JSON.parse @getPageContent()
        test.assert('_id' of parsedContent.tournament, "Tournament created and returned with ID")
        @_tournament_id = parsedContent.tournament._id
        test.assertEqual parsedContent.tournament.organizer_email, 'google1234@example.com', 'Tournament organizer email automatically extracted from user info'

    .thenOpen "#{URL_ROOT}/api/tournaments",
        headers:
            Accept: 'application/json'
    , ->
        parsedContent = JSON.parse @getPageContent()
        test.assertEquals parsedContent.tournaments.length, 1, "One tournament returned from list"
        test.assertEquals parsedContent.tournaments[0]._id, @_tournament_id, "Newly created tournament is in list"

    .thenOpen "#{URL_ROOT}/api/tournaments?after=500",
        headers:
            Accept: 'application/json'
    , ->
        parsedContent = JSON.parse @getPageContent()
        test.assertEquals parsedContent.tournaments.length, 1, "One tournament returned from list after time before start"
        test.assertEquals parsedContent.tournaments[0]._id, @_tournament_id, "Newly created tournament is in list after time before start"

    .thenOpen "#{URL_ROOT}/api/tournaments?after=1500",
        headers:
            Accept: 'application/json'
    , ->
        parsedContent = JSON.parse @getPageContent()
        test.assertEquals parsedContent.tournaments.length, 0, "No tournaments returned from list after time after start"

    .then ->
        @open "#{URL_ROOT}/api/tournament/#{@_tournament_id}",
            method: 'post'
            headers:
                Accept: 'application/json'
            data:
                name: 'Updated tournament'
                event_start_timestamp: 2000
                event_end_timestamp: 3000
                description: "Updated tournament description"
                organizer_email: "new@example.com"
        , ->
            parsedContent = JSON.parse @getPageContent()
            test.assertEqual parsedContent.tournament.name, 'Updated tournament', 'Tournament name updated'
            test.assertEqual parsedContent.tournament.event_start_timestamp, 2000, 'Tournament start time updated'
            test.assertEqual parsedContent.tournament.event_end_timestamp, 3000, 'Tournament end time updated'
            test.assertEqual parsedContent.tournament.description, 'Updated tournament description', 'Tournament description updated'
            test.assertEqual parsedContent.tournament.organizer_email, 'new@example.com', 'Tournament organizer email updated'

    .run ->
        test.done()
