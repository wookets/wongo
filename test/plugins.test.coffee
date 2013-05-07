assert = require 'assert'
wongo = require '../lib/wongo'
_ = require 'underscore'

wongo.schema 'MockPlugin', 
  fields:
    name: String
  plugins: [
    wongo.plugins.timestamp
  ]

wongo.schema 'MockTree',
  fields: 
    name: String
  plugins: [
    wongo.plugins.atree
  ]
      
describe 'Wongo Plugins', ->
  
  it 'should save a MockPlugin and have Dates created for two properties', (done) ->
    doc = {name: 'woof'}
    wongo.save 'MockPlugin', doc, (err, result) ->
      assert.ifError(err)
      assert.ok(result._id)
      assert.ok(result.createdOn)
      assert.ok(_.isDate(result.modifiedOn))
      assert.ok(_.isDate(result.createdOn))
      done()
  
  it 'should have attached ancestor tree methods to wongo namespace', (done) ->
    assert.ok(_.isFunction(wongo.plugins.atree))
    done()

  root = null
  child1 = null
  child11 = null

  it 'should set a root for the tree', (done) ->
    root = {name: 'Root'}
    wongo.save 'MockTree', root, (err, result) ->
      root = result
      assert.ok(_.isArray(root.ancestors))
      done()

  it 'should add a child to the root', (done) ->
    child1 = {name: 'child1'}
    child1.ancestors = [root._id]
    wongo.save 'MockTree', child1, (err, doc) ->
      child1 = doc
      assert.equal(doc.parent, root._id)
      assert.equal(doc.ancestors[0], root._id)
      done()
  
  it 'should add a child to the child', (done) ->
    child11 = {name: 'child11'}
    child11.ancestors = [root._id, child1._id]
    wongo.save 'MockTree', child11, (err, doc) ->
      child11 = doc
      assert.equal(doc.parent, child1._id)
      assert.equal(doc.ancestors[0], root._id)
      assert.equal(doc.ancestors[1], child1._id)
      done()
  
  it 'should get all ascendants of child11', (done) ->
    wongo.findById 'MockTree', child11._id, (err, result) ->
      assert.ok(result)
      assert.equal(result.ancestors.length, 2)
      assert.equal(result.ancestors[0], root._id)
      assert.equal(result.ancestors[1], child1._id)
      done()

  it 'should get all descendants of root', (done) ->
    query = {ancestors: root._id}
    wongo.find 'MockTree', query, (err, result) ->
      assert.ok(result)
      assert.equal(result.length, 2)
      for child in result
        if child.name isnt 'child1' and child.name isnt 'child11'
          assert.ok(false)
      done()
   
  it 'should get all children of root', (done) ->
    query = {parent: root._id}
    wongo.find 'MockTree', query, (err, result) ->
      assert.ok(result)
      assert.equal(result.length, 1)
      assert.equal(result[0].name, child1.name)
      assert.equal(result[0].parent, root._id)
      assert.equal(result[0].ancestors[0], root._id)
      done()
  
  it 'should try to remove child1 and remove child11', (done) ->
    wongo.remove 'MockTree', child1._id, (err) ->
      assert.ok(not err)
      done()
  
  it 'should verify that child11 was removed', (done) ->
    wongo.findById 'MockTree', child11._id, (err, result) ->
      assert.ok(not err)
      assert.ok(not result)
      done()

