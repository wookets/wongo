assert = require 'assert'
wongo = require '../lib/wongo'

wongo.schema 'MockFind', 
  fields: 
    name: String
    selectField: String

describe 'Wongo Find', ->
    
  docs = [{name: 'Meow'}, {name: 'Boo', selectField: 'Cow'}, {name: 'Fran'}, {name: 'Kitty'}, {name: 'Woof'}]
  
  it 'should be able to save all documents', (done) ->
    wongo.save 'MockFind', docs, (err, result) ->
      assert.ifError(err)
      assert.ok(item._id) for item in result
      done()
  
  it 'should be able to find all documents', (done) ->
    query = {}
    wongo.find 'MockFind', query, (err, result) ->
      assert.ifError(err)
      assert.equal(result?.length, 5)
      done()
  
  it 'should be able to find one document from many', (done) ->
    query = {}
    wongo.findOne 'MockFind', query, (err, result) ->
      assert.ifError(err)
      assert.ok(result)
      done()
  
  it 'should be able to find one document by name', (done) ->
    query = {name: 'Boo'}
    wongo.findOne 'MockFind', query, (err, result) ->
      assert.ifError(err)
      assert.equal(result.name, 'Boo')
      done()
  
  it 'should be able to find documents by name', (done) ->
    query = {name: 'Fran'}
    wongo.find 'MockFind', query, (err, result) ->
      assert.ifError(err)
      assert.equal(result.length, 1)
      assert.equal(result[0].name, 'Fran')
      done()

  it 'should be able to find select fields on document', (done) ->
    query = {select: 'name', where: {name: 'Boo'}}
    wongo.findOne 'MockFind', query, (err, result) ->
      assert.ifError(err)
      assert.equal(result.name, 'Boo')
      assert.ok(not result.selectField)
      done()

  it 'should be able to find documents by name with where', (done) ->
    query = {where: {name: 'Fran'}}
    wongo.find 'MockFind', query, (err, result) ->
      assert.ifError(err)
      assert.equal(result.length, 1)
      assert.equal(result[0].name, 'Fran')
      done()
  
  it 'should be able to limit documents to 3', (done) ->
    query = {where: {}, limit: 3}
    wongo.find 'MockFind', query, (err, result) ->
      assert.ifError(err)
      assert.equal(result.length, 3)
      done()