express = require 'express'
nano = require 'nano'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy

Doc = require './lib/doc'
User = require './lib/user'

db = nano(process.env.COUCHDB_URL ? 'http://localhost:5984/xwt-dev')
Doc.use db
require('./lib/designdoc').createViews()

app = express()

app.configure ->
    app.set 'view engine', 'jade'

app.configure 'development', ->
    app.set 'port', 3000

app.configure 'production', ->
    app.set 'port', process.env.PORT ? 80

app.use (req, res, next) ->
    console.log "#{new Date().toUTCString()} #{req.ip} #{req.method} #{req.path}"
    next()

app.use express.cookieParser()
app.use express.bodyParser()
app.use express.session
    secret: process.env.SESSION_SECRET ? 'sekrit'
app.use express.compress()
app.use express.static(__dirname + '/public')
app.use passport.initialize()
app.use passport.session()

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

app.get '/', (req, res) ->
    res.render 'index'

app.get '/login', (req, res) ->
    res.render 'login'

app.post '/login', passport.authenticate 'local', {
        successRedirect: '/protected'
        failureRedirect: '/login'
    }

app.get '/protected', (req, res) ->
    unless req.user?
        res.redirect '/login'
    else
        res.locals.user = req.user
        res.render 'protected'

app.listen app.get('port')
console.log "Listening on port #{app.get 'port'}..."
