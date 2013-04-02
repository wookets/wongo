assert = require 'assert'
wongo = require '../lib/wongo'
_ = require 'underscore'


wongo.schema 'MockPlugin', 
  fields:
    name: String
  plugins: [
    wongo.plugins.timestamp
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
  