assert = require 'assert'
wongo = require '../lib/wongo'

wongo.schema 'MockAll', 
  fields: 
    name: String

describe 'Wongo CRUD All', ->
    
  #
  # multi crud
  #
  docs = [{name: 'Meow'}, {name: 'Boo'}, {name: 'Fran'}]
  it 'should be able to save all documents', (done) ->
    wongo.saveAll 'MockAll', docs, (err, result) ->
      assert.ifError(err)
      assert.ok(item._id) for item in result
      done()
  it 'should be able to remove all documents', (done) ->
    _ids = (doc._id for doc in docs)
    wongo.removeAll 'MockAll', _ids, (err, result) ->
      assert.ifError(err)
      done()
  