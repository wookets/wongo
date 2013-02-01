assert = require 'assert'
async = require 'async'

wongo = require '../lib/wongo'

require './db_setup'


describe 'Wongo', ->

  mock1 = null

  it 'should start with a fresh database', (done) -> 
    wongo.clear('Mock', done)

  it 'should save a Mock named mint', (done) ->
    resource = {name: 'mint'}
    wongo.save 'Mock', resource, (err, doc) ->
      assert.ok(doc?._id)
      assert.equal(doc.name, 'mint')
      assert.equal(doc._type, 'Mock')
      mock1 = doc
      done()
  
  it.skip 'should fail to save a Mock named nothing', (done) ->
    resource = {}
    wongo.save 'Mock', resource, (err, doc) ->
      assert.ok(err)
      assert.equal(err.name, 'ValidationError')
      #assert.ok(doc?._id)
      #assert.equal(doc.name, 'mint')
      #mock1 = doc
      done()
  
  it 'should find a Mock named mint', (done) ->
    query = {where: {name: 'mint'}}
    wongo.find 'Mock', query, (err, mocks) ->
      assert.ok(mocks)
      assert.equal(mocks.length, 1)
      assert.equal(mocks[0].name, 'mint')
      done()
  it 'should find a Mock named mint without where', (done) ->
    query = {name: 'mint'}
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
  it 'should find one Mock named mint without where', (done) ->
    query = {name: 'mint'}
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
    wongo.save 'Mock', {_id: mock1._id, name: 'minty'}, (err) ->
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
    wongo.save 'Mock', parent_mock, (err, doc) ->
      parent_mock = doc
      child_mock.parent = parent_mock
      child2_mock.parent = parent_mock
      wongo.saveAll 'Mock', [child_mock, child2_mock], (err, children) ->
        for child in children
          if child.name is 'child' then child_mock = child else child2_mock = child
        done()
  
  it 'should populate the parent on a child', (done) -> # singular reference populate
    wongo.find 'Mock', {where: {_id: {$in: [child_mock._id, child2_mock._id]}}, populate: ['parent']}, (err, docs) ->
      assert.equal(docs?.length, 2)
      for doc in docs
        assert.ok(doc.parent?._id)
      done() 
    
  it 'should add the children to the parent', (done) ->
    parent_mock.children ?= []
    parent_mock.children.push(child_mock)
    parent_mock.children.push(child2_mock)
    wongo.save 'Mock', parent_mock, (err, doc) ->
      assert.equal(doc?.children?.length, 2)
      done()
  
  it 'should populate the children on the parent', (done) -> # array based populate
    wongo.findOne 'Mock', {where: {_id: parent_mock._id}, populate: ['children']}, (err, doc) ->
      assert.equal(doc?.children?.length, 2)
      for child in doc.children
        assert.ok(child._id)
      done()
  
  it 'should add a third child object after populate', (done) ->
    done()
  
  mockp = {name: 'plugin', plugin1: 'woofer', plugin2: 'cat'}
  it 'should make sure plugin1 and plugin2 are added to schema', (done) ->
    wongo.save 'Mock', mockp, (err, doc) ->
      assert.equal(doc.plugin1, 'woofer')
      assert.equal(doc.plugin2, 'cat')
      done()
      
  mockh = {name: 'hook'}
  it 'should make sure hooks fire', (done) ->
    wongo.save 'Mock', mockh, (err, doc) ->
      assert.equal(doc.beforeSave, 'changed')
      assert.equal(doc.afterSave, 'changed')
      done()
    
  mockarray = {name: 'array', array: ['mike', 'joe', 'phil']}
  it 'should make sure arrays are saved', (done) ->
    wongo.save 'Mock', mockarray, (err, doc) ->
      mockarray = doc
      assert.equal(doc.array?.length, 3)
      assert.equal(doc.array[0], 'mike')
      assert.equal(doc.array[1], 'joe')
      assert.equal(doc.array[2], 'phil')
      done()
  it 'should make sure arrays are updated', (done) ->
    mockarray.array = ['joe', 'phil', 'mike']
    wongo.save 'Mock', mockarray, (err, doc) ->
      assert.equal(doc.array?.length, 3)
      assert.equal(doc.array[0], 'joe')
      assert.equal(doc.array[1], 'phil')
      assert.equal(doc.array[2], 'mike')
      done()
    
  mockea = {name: 'array', embedded_array: [{name: 'meow'}, {name: 'ham'}, {name: 'mike'}]}
  it 'should make sure embedded arrays are saved', (done) ->
    wongo.save 'Mock', mockea, (err, doc) ->
      mockea = doc
      assert.equal(doc.embedded_array?.length, 3)
      assert.equal(doc.embedded_array[0].name, 'meow')
      assert.equal(doc.embedded_array[1].name, 'ham')
      assert.equal(doc.embedded_array[2].name, 'mike')
      done()
  
  it 'should make sure embedded arrays are updated', (done) ->
    mockea.embedded_array = [{name: 'meow'}, {name: 'phil'}, {name: 'mike'}]
    wongo.save 'Mock', mockea, (err, doc) ->
      assert.equal(doc.embedded_array?.length, 3)
      assert.equal(doc.embedded_array[0].name, 'meow')
      assert.equal(doc.embedded_array[1].name, 'phil')
      assert.equal(doc.embedded_array[2].name, 'mike')
      done()
  
  it 'should make sure embedded arrays can be added to', (done) ->
    mockea.embedded_array.push({name: 'woof'})
    wongo.save 'Mock', mockea, (err, doc) ->
      assert.equal(doc.embedded_array?.length, 4)
      assert.equal(doc.embedded_array[3].name, 'woof')
      done()
      
  it 'should make sure embedded arrays can be shuffled', (done) ->
    temp = mockea.embedded_array[0]
    mockea.embedded_array[0] = mockea.embedded_array[3]
    mockea.embedded_array[3] = temp
    wongo.save 'Mock', mockea, (err, doc) ->
      assert.equal(doc.embedded_array[0].name, 'woof')
      assert.equal(doc.embedded_array[3].name, 'meow')
      done()
  
  mockeoa = {name: 'em obj array', embedded_array2: [{name: 'bones', ref_array: []}]}
  it 'should make sure embedded ref arrays can be added', (done) ->
    mockeoa.embedded_array2[0].ref_array = [parent_mock._id, child_mock._id]
    wongo.save 'Mock', mockeoa, (err, doc) ->
      assert.equal(doc.embedded_array2[0].ref_array.length, 2)
      assert.equal(doc.embedded_array2[0].ref_array[0], parent_mock._id)
      assert.equal(doc.embedded_array2[0].ref_array[1], child_mock._id)
      done()
      
  it 'should make sure embedded ref arrays can be shuffled', (done) ->
    temp = mockeoa.embedded_array2[0].ref_array[0]
    mockeoa.embedded_array2[0].ref_array[0] = mockeoa.embedded_array2[0].ref_array[1]
    mockeoa.embedded_array2[0].ref_array[1] = temp
    wongo.save 'Mock', mockeoa, (err, doc) ->
      assert.equal(doc.embedded_array2[0].ref_array.length, 2)
      assert.equal(doc.embedded_array2[0].ref_array[1], parent_mock._id)
      assert.equal(doc.embedded_array2[0].ref_array[0], child_mock._id)
      done()
      
  it 'should cleanup the database', (done) -> 
    wongo.clear('Mock', done)

