assert = require 'assert'
wongo = require '../lib/wongo'


wongo.schema 'MockStrict', 
  fields: 
    name: String # simplest property
    mixed: {type: 'mixed'} # support mixed types
    child: 
      name: String
      grandchild: 
        name: String
    children: [
      name: String
      grandchildren: [
        name: String
      ]
    ]

describe 'Wongo Strict', ->
  
  it 'should prune any values not on the schema', (done) ->
    doc = {name: 'wallace', dog: 'gromit'}
    wongo.save 'MockStrict', doc, (err, result) ->
      assert.ifError(err)
      assert.equal(result.name, 'wallace')
      assert.ok(not result.dog)
      done()
  
  it 'should ignore if something is put into a mixed type property', (done) ->
    doc = {name: 'meow', mixed: 'stinger'}
    wongo.save 'MockStrict', doc, (err, result) ->
      assert.ifError(err)
      assert.equal(result.name, 'meow')
      assert.equal(result.mixed, 'stinger')
      done()
  
  it 'should prune any values not on a child schema', (done) ->
    doc = {name: 'wallace', child: {name: 'pete', dog: 'grommit'}}
    wongo.save 'MockStrict', doc, (err, result) ->
      assert.ifError(err)
      assert.equal(result.child.name, 'pete')
      assert.ok(not result.child.dog)
      done()
  
  it 'should prune any values not on a grandchild schema', (done) ->
    doc = {name: 'wallace', child: {name: 'pete', grandchild: {name: 'bum', dog: 'buca'}}}
    wongo.save 'MockStrict', doc, (err, result) ->
      assert.ifError(err)
      assert.equal(result.child.grandchild.name, 'bum')
      assert.ok(not result.child.grandchild.dog)
      done()
  
  it 'should prune any values not on a children schema', (done) ->
    doc = {name: 'wallace', children: [{name: 'bum', dog: 'meow'}]}
    wongo.save 'MockStrict', doc, (err, result) ->
      assert.ifError(err)
      assert.equal(result.children[0].name, 'bum')
      assert.ok(not result.children[0].dog)
      done()