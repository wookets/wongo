# assert = require 'assert'
# wongo = require '../lib/wongo'
# 
# 
# wongo.schema 'MockPrune', 
#   fields: 
#     name: String
#     array: [String]
#     arrayObj: [
#       name: String
#     ]
#     subdoc: 
#       name: String
#       subdoc: 
#         name: String
#         array: [String]
# 
# describe 'Wongo Prune', ->
#   schema = wongo.schema('MockPrune')
#   
#   it 'should be able to prune a simple document', (done) ->
#     doc = {name: 'Meow', field: 'Mixer'}
#     wongo.prune(doc, schema.fields)
#     assert.equal(doc.name, 'Meow')
#     assert.ok(not doc.field)
#     done()
#   
#   it 'should be able to prune an array', (done) ->
#     doc = {name: 'Meow', field: 'Mixer', fieldArray: [], array: ['meow', 'woof']}
#     wongo.prune(doc, schema.fields)
#     assert.equal(doc.name, 'Meow')
#     assert.ok(not doc.field)
#     assert.ok(not doc.fieldArray)
#     assert.equal(doc.array[0], 'meow')
#     assert.equal(doc.array[1], 'woof')
#     done()
#   
#   it 'should be able to prune subdocuments', (done) ->
#     doc = {name: 'Meow', subdoc: {name: 'Happy', field: 'remmmy'}}
#     wongo.prune(doc, schema.fields)
#     assert.equal(doc.name, 'Meow')
#     assert.equal(doc.subdoc.name, 'Happy')
#     assert.ok(not doc.subdoc.field)
#     done()
#   
#   it 'should be able to prune sub-subdocuments', (done) ->
#     doc = {name: 'Meow', subdoc: {name: 'Happy', subdoc: {name: 'Wally', field: 'Chese'}}}
#     wongo.prune(doc, schema.fields)
#     assert.equal(doc.name, 'Meow')
#     assert.equal(doc.subdoc.subdoc.name, 'Wally')
#     assert.ok(not doc.subdoc.subdoc.field)
#     done()
#   
#   it 'should be able to prune sub-subdocument arrays', (done) ->
#     doc = {name: 'Meow', subdoc: {subdoc: {array: ['Wally'], field: ['meowpants']}}}
#     wongo.prune(doc, schema.fields)
#     assert.equal(doc.name, 'Meow')
#     assert.equal(doc.subdoc.subdoc.array[0], 'Wally')
#     assert.ok(not doc.subdoc.subdoc.field)
#     done()
#   
#   it 'should be able to prune arrayed sub document fields', (done) ->
#     doc = {name: 'Meow', arrayObj: [{name: 'meowpants', field: 'wall'}]}
#     wongo.prune(doc, schema.fields)
#     assert.equal(doc.name, 'Meow')
#     assert.equal(doc.arrayObj[0].name, 'meowpants')
#     assert.ok(not doc.arrayObj[0].field)
#     done()