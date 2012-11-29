assert = require 'assert'

wongo = require '../lib/wongo'

require './db_setup'

describe 'Wongo', ->

  mock1 = null

  it 'should start with a fresh database', (done) -> 
    wongo.clear 'Mock', (err, result) -> # this will take a while, because mongoose will still be setting up the db connection
      done()

  it 'should save a Mock named mint', (done) ->
    resource = {_type: 'Mock', name: 'mint'}
    wongo.save 'Mock', resource, (err, doc) ->
      if err then console.log err
      assert.ok(doc)
      assert.ok(doc._id)
      assert.equal(doc.name, 'mint')
      assert.equal(doc._type, 'Mock')
      mock1 = doc
      done()
  
  it 'should find a Mock named mint', (done) ->
    query = {where: {name: 'mint'}}
    wongo.find 'Mock', query, (err, mocks) ->
      assert.ok(mocks)
      assert.equal(mocks.length, 1)
      assert.equal(mocks[0].name, 'mint')
      done()
 
  it 'should find one Mock named mint', (done) ->
    query = {where: {name: 'mint'}}
    wongo.findOne 'Mock', query, (err, mock) ->
      assert.ok(mock)
      assert.equal(mock.name, 'mint')
      done()
      
  it 'should find Mock by _id', (done) ->
    wongo.findById 'Mock', mock1._id, (err, mock) ->
      assert.ok(mock)
      assert.equal(mock.name, 'mint')
      done()
      
  it 'should update mints name to minty', (done) ->
    wongo.update 'Mock', {name: 'mint'}, {name: 'minty'}, (err) ->
      assert.ok(not err)
      wongo.findById 'Mock', mock1._id, (err, mock) ->
        assert.ok(mock)
        assert.equal(mock.name, 'minty')
        done()

  it 'should remove the Mock1', (done) ->
    wongo.remove 'Mock', mock1._id, (err) ->
      assert.ok(not err)
      done()
      
  list_o_mocks = [{name: 'Larry'}, {name: 'Curly'}, {name: 'Moe'}]
  
  it 'should save all the new Mocks', (done) ->
    wongo.saveAll 'Mock', list_o_mocks, (err, docs) ->
      assert.ok(docs)
      assert.ok(docs.length, 3)
      list_o_mocks = docs
      done()
  
  it 'should remove all the new Mocks', (done) ->
    _ids = (mock._id for mock in list_o_mocks)
    wongo.removeAll 'Mock', _ids, (err) ->
      assert.ok(not err)
      done()
      
  it 'should verify all the new Mocks were removed', (done) ->
    wongo.find 'Mock', {}, (err, mocks) ->
      assert.ok(not err)
      assert.ok(mocks)
      assert.equal(mocks.length, 0)
      done()
      
  it 'should cleanup the database', (done) ->
    wongo.clear 'Mock', (err, result) -> # end with a fresh db
      done()