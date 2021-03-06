express = require 'express'
nano = require 'nano'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

Doc = require './lib/doc'
Match = require './lib/match'
Tournament = require './lib/tournament'
User = require './lib/user'

db = nano(process.env.COUCHDB_URL ? 'http://localhost:5984/xwt-dev')
Doc.use db
require('./lib/designdoc').createViews()

# Express configuration

app = express()

app.configure ->
    app.set 'view engine', 'jade'

app.configure 'development', ->
    app.set 'port', 3000

app.configure 'production', ->
    app.set 'port', process.env.PORT ? 80

# Middleware

app.use (req, res, next) ->
    console.log "#{new Date().toUTCString()} #{req.ip} #{req.method} #{req.path}"
    next()
app.use express.cookieParser()
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.session
    secret: process.env.SESSION_SECRET ? 'sekrit'
app.use express.compress()
app.use express.static(__dirname + '/public')
app.use passport.initialize()
app.use passport.session()

# Passport configuration

passport.use new LocalStrategy (username, password, done) ->
    # username == fake oauth id
    # password == fake oauth strat
    User.find password, username
    .then (user) ->
        done null, user
    .fail (err) ->
        done err, null

passport.serializeUser (user, done) ->
    done null, user._id

passport.deserializeUser (user_id, done) ->
    User.fetch user_id
    .then (user) ->
        done null, user
    .fail (err) ->
        done err, null

# Routes

# Public UI

app.get '/', (req, res) ->
    res.render 'index'

app.get '/login', (req, res) ->
    res.render 'login'

app.post '/login', passport.authenticate 'local', {
        successRedirect: '/protected'
        failureRedirect: '/login'
    }

# Public API

app.get '/api/tournaments', (req, res) ->
    # show upcoming tournaments
    #
    # if query args includes `after`, only shows tournaments
    # after that unix timestamp.
    Tournament.getAll req.query.after ? null
    .then (rows) ->
        res.json { tournaments: rows }

# Routes from this point on will require authentication

app.all '*', (req, res, next) ->
    unless req.user?
        res.redirect '/login'
    else
        res.locals.user = req.user
        next()

app.get '/protected', (req, res) ->
    res.locals.user = req.user
    res.render 'protected'

# Protected UI

app.get '/tournament', (req, res) ->
    res.render 'tournament/index'

app.get '/tournament/new', (req, res) ->
    res.locals.now = parseInt((new Date()).getTime() / 1000)
    res.render 'tournament/new'

# Protected API

app.post '/api/user/:id', (req, res) ->
    User.fetch req.params.id
    .then (user) ->
        user.email = req.body.email if req.body.email?
        User.save user
    .fail (err) ->
        throw err

app.get '/api/user/:id/tournamentsCreated', (req, res) ->
    throw new Error "Not yet implemented"

app.get '/api/user/:id/tournamentsEntered', (req, res) ->
    throw new Error "Not yet implemented"


app.get '/api/tournament/:id', (req, res) ->
    doc = {}
    Tournament.fetch req.params.id
    .then (tournament) ->
        doc.tournament = tournament
    .then ->
        res.json doc

app.put '/api/tournament', (req, res) ->
    Tournament.save
        name: req.body.name
        event_start_timestamp: req.body.event_start_timestamp
        event_end_timestamp: req.body.event_end_timestamp
        description: req.body.description
        organizer_email: req.body.organizer_email ? req.user.email
        organizer_user_id: req.user._id
    .then (r) ->
        res.redirect "/api/tournament/#{r.id}"
    .fail (err) ->
        throw err

app.post '/api/tournament/:id', (req, res) ->
    Tournament.fetch req.params.id
    .then (tournament) ->
        throw new Error "You are not the tournament organizer" unless req.user._id == tournament.organizer_user_id
        tournament.name = req.body.name if req.body.name
        tournament.event_start_timestamp = req.body.event_start_timestamp if req.body.event_start_timestamp
        tournament.event_end_timestamp = req.body.event_end_timestamp if req.body.event_end_timestamp
        tournament.description = req.body.description if req.body.description
        tournament.organizer_email = req.body.organizer_email if req.body.organizer_email
        Tournament.save tournament
    .then (r) ->
        res.redirect "/api/tournament/#{r.id}"
    .fail (err) ->
        throw err

app.delete '/api/tournament/:id', (req, res) ->
    throw new Error "Not yet implemented"

app.get '/api/tournament/:id/rounds', (req, res) ->
    Tournament.getRounds req.params.id
    .then (rounds) ->
        res.json {rounds: rounds}
    .fail (err) ->
        throw err

app.get '/api/tournament/:id/matches/:round', (req, res) ->
    Tournament.getMatches id, round
    .then (matches) ->
        res.json {matches: matches}
    .fail (err) ->
        throw err


app.get '/api/match/:id', (req, res) ->
    Match.fetch req.params.id
    .then (match) ->
        res.json match
    .fail (err) ->
        throw err

app.put '/api/match', (req, res) ->
    Match.new req.body.tournament_id, req.body.round, req.body.list1_id, req.body_list2_id
    .then (res) ->
        res.redirect "/api/match/#{res.id}"
    .fail (err) ->
        throw err

# Fire it up!

app.listen app.get('port')
console.log "Listening on port #{app.get 'port'}..."
