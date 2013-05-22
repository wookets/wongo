assert = require 'assert'
wongo = require '../lib/wongo'

wongo.schema 'MockSubdoc',
  fields:
    name: String # simplest property
    subdoc:
      name: String
      m1: {type: Number}
      m2: {type: Number}

describe 'Wongo Subdoc', ->
  doc = null

  it 'should save a doc with a subdoc', (done) ->
    doc =
      name: 'wallace'
      subdoc:
        name: 'grommit'
        m1: 1
    wongo.save 'MockSubdoc', doc, (err, result) ->
      assert.ifError(err)
      assert.equal(result.name, 'wallace')
      assert.equal(result.subdoc.m1, 1)
      done()

  it 'should update a doc with a subdoc', (done) ->
    doc.subdoc.m2 = 3
    wongo.save 'MockSubdoc', doc, (err, result) ->
      assert.ifError(err)
      assert.equal(result.name, 'wallace')
      assert.equal(result.subdoc.m2, 3)
      done()

  it 'should update a partial doc with a subdoc', (done) ->
    doc2 = {_id: doc._id, name: 'mocha', subdoc: {_id: doc.subdoc._id, m2: 5}}
    wongo.save 'MockSubdoc', doc2, (err, result) ->
      assert.ifError(err)
      assert.equal(result.name, 'mocha')
      assert.equal(result.subdoc.m2, 5)
      assert.ok(not result.subdoc.m1)
      done()

  it 'should update a partial doc with a subdoc', (done) ->
    doc2 = {_id: doc._id, name: 'mint', subdoc: {m2: 15}}
    wongo.save 'MockSubdoc', doc2, (err, result) ->
      assert.ifError(err)
      assert.equal(result.name, 'mint')
      assert.equal(result.subdoc.m2, 15)
      assert.notEqual(result.subdoc._id, doc.subdoc._id)
      done()