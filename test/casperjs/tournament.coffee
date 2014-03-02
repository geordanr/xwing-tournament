{spawn} = require 'child_process'
uuid = require 'node-uuid'

express_proc = null
dbname = "http://localhost:5984/xwing-tournament-test-server-#{uuid.v4()}"

SERVER_STARTUP_MSEC = 1500
URL_ROOT = 'http://localhost:3000'

casper.test.setUp ->
    express_proc = spawn 'env', [ "COUCHDB_URL=#{dbname}", 'coffee', 'server.coffee' ]
    express_proc.stdout.on 'data', (data) ->
        casper.log data, 'debug'
    express_proc.stderr.on 'data', (data) ->
        casper.log data, 'debug'
    spawn 'curl', [ '-X', 'PUT', dbname ]

casper.test.tearDown ->
    express_proc.kill()
    spawn 'curl', [ '-X', 'DELETE', dbname ]

casper.test.begin 'Server starts up', 1, (test) ->
    casper.start()

    .then ->
        @wait SERVER_STARTUP_MSEC

    .thenOpen "#{URL_ROOT}", ->
        test.assertTextExists 'Hello World'

    .run ->
        test.done()

casper.test.begin 'Denies unauthenticated users', 1, (test) ->
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

    .run ->
        test.done()

casper.test.begin 'Allows authentication of (faked) OAuth user via local auth', 1, (test) ->
    casper.start()

    .then ->
        @wait SERVER_STARTUP_MSEC

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
        test.assertTextExists "google1234@example.com"

    .run ->
        test.done()

casper.test.begin 'Tournament API: Shows no tournaments when there are none', 1, (test) ->
    casper.start()

    .then ->
        @wait SERVER_STARTUP_MSEC

    .thenOpen "#{URL_ROOT}/api/tournaments",
        method: 'get'
        headers:
            Accept: 'application/json'
    , ->
        parsedContent = JSON.parse @getPageContent()
        test.assertEquals parsedContent, {tournaments: []}, "Returns empty list"

    .run ->
        test.done()

casper.test.begin 'Tournament API: new tournament shows up in list', 2, (test) ->
    casper.start()

    .then ->
        @wait SERVER_STARTUP_MSEC

    .thenOpen "#{dbname}/user-1",
        method: 'put'
        data: JSON.stringify
            type: 'user'
            oauth_strategy: 'google'
            oauth_id: '1234'
            email: 'google1234@example.com'
    , ->
        parsedContent = JSON.parse @getPageContent()
        test.assertTrue parsedContent.ok, "Fake OAuth user was created"

    .thenOpen "#{URL_ROOT}/login", ->
        @fill 'form',
            username: '1234'
            password: 'google'
        , true

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
        test.assert('_id' of parsedContent.tournament, "Tournament was created")

    .run ->
        test.done()
