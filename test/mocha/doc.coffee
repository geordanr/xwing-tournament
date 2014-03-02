# Run this with mocha
Q = require 'q'
nano = require 'nano'
uuid = require 'node-uuid'

server = nano 'http://localhost:5984'

Doc = require '../../lib/doc'

make_doc = ->
    foo: 42
    bar: [ 'a', 'b', 'c' ]

describe "Doc", ->
    beforeEach (done) ->
        dbname = "xwing-tournament-test-#{@currentTest.title.toLowerCase().replace /[^a-z0-9]/g, '-'}-#{uuid.v4()}"
        #console.log "Create #{dbname}"
        Q.nfcall server.db.create, dbname
        .then =>
            @db = server.use dbname
            Doc.use @db
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

    it "saves raw", ->
        res = Doc.saveRaw make_doc()
        Q.all [
            res.should.eventually.have.property 'id'
            res.should.eventually.have.property 'rev'
        ]

    it "saves with retries", ->
        res = Doc.saveWithRetries make_doc()
        Q.all [
            res.should.eventually.have.property 'id'
            res.should.eventually.have.property 'rev'
        ]

    it "saves over existing doc with retries", ->
        doc = make_doc()
        doc._id = 'foobar'

        old_rev = null

        res = Doc.saveRaw doc
        .then (body) =>
            old_rev = body.rev
            Doc.saveWithRetries doc

        res.should.eventually.not.have.property 'rev', old_rev

    it "fetches documents that have been saved", ->
        doc = Doc.saveRaw make_doc()
        .then (body) ->
            Doc.fetchDoc body.id

        expected_doc = make_doc()

        Q.all [
            doc.should.eventually.have.property '_id'
            doc.should.eventually.have.property '_rev'
            doc.should.eventually.have.property 'foo'
            doc.should.eventually.have.property 'bar'
        ]

    it "enforces type and properties when saving", ->
        doc = make_doc()
        type = 'test_doc'

        doc = Doc.saveDoc doc, type, [ 'foo' ]
        .then (body) ->
            Doc.fetchDoc body.id

        doc.should.eventually.have.property 'type', type

    it "destroys documents", ->
        id = null
        rev = null

        res = Doc.saveRaw make_doc()
        .then (body) ->
            id = body.id
            rev = body.rev
            Doc.destroyDoc id, rev
        .then ->
            Doc.fetchDoc id

        res.should.eventually.be.rejectedWith Error
