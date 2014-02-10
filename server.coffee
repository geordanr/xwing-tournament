express = require 'express'
engines = require 'consolidate'

app = express()

app.configure () ->
    app.set 'view engine', 'jade'

app.configure 'development', () ->
    app.set 'port', 3000

app.configure 'production', () ->
    app.set 'port', process.env.PORT ? 80

app.use (req, res, next) ->
    console.log "#{new Date().toUTCString()} #{req.ip} #{req.method} #{req.path}"
    next()

app.use express.compress()

app.use express.static(__dirname + '/public')

app.get '/', (req, res) ->
    res.render 'index'

app.listen app.get('port')
console.log "Listening on port #{app.get 'port'}..."
