assert = require 'assert'
async = require 'async'

wongo = require '../lib/wongo'

require './db_setup'

describe 'Wongo', ->

  mock1 = null

  it 'should start with a fresh database', (done) -> 
    async.forEach ['Mock', 'MockChild', 'MockParent'], (_type, nextInLoop) ->
      wongo.clear(_type, nextInLoop)
    , (err) ->
      assert.ok(not err)
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
  
  it 'should count the new Mocks', (done) ->
    wongo.count 'Mock', {}, (err, num) ->
      assert.ok(not err)
      assert.equal(num, 3)
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
      
  parent_mock = {name: 'parent'}
  child_mock = {name: 'child'}
  child2_mock = {name: 'child2'}
  
  it 'should save a parent and two children', (done) ->
    wongo.save 'MockParent', parent_mock, (err, doc) ->
      parent_mock = doc
      child_mock.parent = parent_mock
      child2_mock.parent = parent_mock
      wongo.saveAll 'MockChild', [child_mock, child2_mock], (err, children) ->
        for child in children
          if child.name is 'child'
            child_mock = child
          else
            child2_mock = child
        done()
  
  it 'should populate the parent on a child', (done) -> # singular reference populate
    wongo.find 'MockChild', {populate: ['parent']}, (err, docs) ->
      assert.ok(docs)
      assert.equal(docs.length, 2)
      for doc in docs
        assert.ok(doc.parent)
        assert.ok(doc.parent._id)
      done() 
    
  it 'should add the children to the parent', (done) ->
    parent_mock.children ?= []
    parent_mock.children.push(child_mock)
    parent_mock.children.push(child2_mock)
    wongo.save 'MockParent', parent_mock, (err, doc) ->
      assert.ok(doc)
      assert.ok(doc.children)
      assert.equal(doc.children.length, 2)
      done()
  
  it 'should populate the children on the parent', (done) -> # array based populate
    wongo.findOne 'MockParent', {populate: ['children']}, (err, doc) ->
      assert.ok(doc)
      assert.ok(doc.children)
      assert.equal(doc.children.length, 2)
      for child in doc.children
        assert.ok(child._id)
      done()
  
  it 'should add a third child object after populate', (done) ->
    done()
      
  it 'should cleanup the database', (done) -> 
    async.forEach ['Mock', 'MockChild', 'MockParent'], (_type, nextInLoop) ->
      wongo.clear(_type, nextInLoop)
    , (err) ->
      assert.ok(not err)
      done()