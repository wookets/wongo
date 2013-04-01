assert = require 'assert'
wongo = require '../lib/wongo'

wongo.schema 'Mock', 
  fields: 
    name: String
    field2: String

describe 'Wongo CRUD', ->
  
  doc = {name: 'Meow'}
  it 'should be able to save a document', (done) ->
    wongo.save 'Mock', doc, (err, result) ->
      assert.ifError(err)
      assert.ok(result?._id)
      doc = result
      done()
  
  it 'should be able to update a document', (done) ->
    doc.name = 'Moo'
    wongo.save 'Mock', doc, (err, result) ->
      assert.ifError(err)
      assert.ok(result)
      assert.equal(result._id, doc._id)
      assert.equal(result.name, 'Moo')
      done()
  
  it 'should be able to update a minified document', (done) ->
    mini_doc = {_id: doc._id, field2: 'mantis'}
    wongo.save 'Mock', mini_doc, (err, result) ->
      assert.ifError(err)
      assert.ok(not result.name)
      assert.equal(result.field2, 'mantis')
      doc.field2 = result.field2
      done()
  
  it 'should be able to unset a field by using null', (done) ->
    mini_doc = {_id: doc._id, field2: null}
    wongo.save 'Mock', mini_doc, (err, result) ->
      assert.ifError(err)
      assert.ok(not result.name)
      assert.ok(not result.field2)
      done()
  
  it 'should be able to find a document', (done) ->
    query = {name: 'Moo'}
    wongo.find 'Mock', query, (err, result) ->
      assert.ifError(err)
      assert.ok(result)
      assert.equal(result[0]._id, doc._id)
      done()
  
  it 'should be able to find one document', (done) ->
    query = {name: 'Moo'}
    wongo.findOne 'Mock', query, (err, result) ->
      assert.ifError(err)
      assert.ok(result)
      assert.equal(result._id, doc._id)
      done()
  
  it 'should be able to find a document findById', (done) ->
    wongo.findById 'Mock', doc._id, (err, result) ->
      assert.ifError(err)
      assert.equal(result?._id, doc._id)
      done()
  
  it 'should be able to remove a document', (done) ->
    wongo.remove 'Mock', doc, (err) ->
      assert.ifError(err)
      done()
      
      