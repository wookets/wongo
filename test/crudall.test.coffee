_ = require 'underscore'
assert = require 'assert'
wongo = require '../lib/wongo'

wongo.schema 'MockAll', 
  fields: 
    name: String

describe 'Wongo CRUD All', ->

  docs = [{name: 'Meow'}, {name: 'Boo'}, {name: 'Fran'}]

  it 'should be able to save all documents', (done) ->
    wongo.save 'MockAll', docs, (err, result) ->
      assert.ifError(err)
      assert.ok(item._id) for item in result
      done()
  it 'should be able to remove all documents', (done) ->
    wongo.remove 'MockAll', docs, (err, result) ->
      assert.ifError(err)
      done()
  it 'should be verify all this worked with a find', (done) ->
    _ids = _.pluck(docs, '_id')
    query = {_id: {$in: _ids}}
    wongo.find 'MockAll', query, (err, result) ->
      assert.ifError(err)
      assert.equal(result.length, 0)
      done()
  it 'should be able to save all documents', (done) ->
    wongo.save 'MockAll', docs, (err, result) ->
      assert.ifError(err)
      assert.ok(item._id) for item in result
      done()
  it 'should be able to remove all documents by id', (done) ->
    _ids = _.pluck(docs, '_id')
    wongo.remove 'MockAll', _ids, (err, result) ->
      assert.ifError(err)
      done()
  it 'should be verify all this worked with a find', (done) ->
    _ids = _.pluck(docs, '_id')
    query = {_id: {$in: _ids}}
    wongo.find 'MockAll', query, (err, result) ->
      assert.ifError(err)
      assert.equal(result.length, 0)
      done()
  
  