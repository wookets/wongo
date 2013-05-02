assert = require 'assert'
wongo = require '../lib/wongo'

wongo.schema 'MockEmbed', 
  fields: 
    name: String
    child: # object
      name: String
      child: 
        name: String
    children: [ # array
      name: String
      children: [
        name: String
      ]
    ]

describe 'Wongo Embedded', ->
  
  doc = 
    name: 'KingMeow'
    child: 
      name: 'KitMeow'
      child: 
        name: 'KittyMeow'
    children: [{
      name: 'KitcMeow',
      children: [
        {name: 'SubKitchMeow'}, {name: 'SubKitchMeow2'}
      ]
    }, {
      name: 'KitcMeow2'
      children: []
    }]
    
  it 'should be able to save an embedded document', (done) ->
    wongo.save 'MockEmbed', doc, (err, result) ->
      assert.ifError(err)
      assert.ok(result?._id)
      doc = result
      assert.equal(doc.name, 'KingMeow')
      assert.equal(doc.child.name, 'KitMeow')
      assert.ok(doc.child._id)
      assert.equal(doc.child.child.name, 'KittyMeow')
      #assert.ok(doc.child.child._id)
      assert.equal(doc.children.length, 2)
      assert.equal(doc.children[0].name, 'KitcMeow')
      assert.equal(doc.children[1].name, 'KitcMeow2')
      assert.equal(doc.children[0].children.length, 2)
      done()