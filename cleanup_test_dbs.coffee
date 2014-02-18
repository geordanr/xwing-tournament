server = require('nano') 'http://localhost:5984'
server.db.list (err, dbs) ->
    if err
        throw err
    else
        for db in dbs
            if db.indexOf('xwing-tournament-test') == 0
                console.log "removing db #{db}"
                server.db.destroy db
