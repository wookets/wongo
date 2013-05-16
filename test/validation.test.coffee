assert = require 'assert'
wongo = require '../lib/wongo'

wongo.schema 'MockValidation', 
  fields: 
    name: {type: String, required: true, min: 3, max: 12} # simplest property
    number: {type: Number, required: true, min: -1, max: 10} # a number property
    boolean: {type: Boolean, required: true} # a boolean property
    array: [{type: String, required: true}]
    date: {type: Date, required: true}
    enum: {type: String, required: true, enum: ['woof', 'bark', 'meow']}
    default: {type: String, required: true, enum: ['cave', 'man'], default: 'cave'}
    defaultBoolean: {type: Boolean, required: true, default: false}
    

describe 'Wongo validation', ->
  
  it 'should validate name exists', (done) ->
    vdoc = {array: []}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'name is required.')
      done()
  
  it 'should validate number exists', (done) ->
    vdoc = {name: 'meow', array: []}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'number is required.')
      done()
  
  it 'should validate boolean exists', (done) ->
    vdoc = {name: 'meow', number: 0, array: []}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'boolean is required.')
      done()
  
  it 'should validate array exists', (done) ->
    vdoc = {name: 'meow', number: 0, boolean: true}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'array is required.')
      done()
  
  it 'should validate date exists', (done) ->
    vdoc = {name: 'meow', number: 0, boolean: true, array: []}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'date is required.')
      done()
  
  it 'should validate name is a string', (done) ->
    vdoc = {name: 45, number: 0, boolean: true, array: [], date: new Date, enum: 'woof'}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'name needs to be a string.')
      done()
  
  it 'should validate date is a date', (done) ->
    vdoc = {name: 'meow', number: 0, boolean: true, array: [], date: 'notdate'}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'date needs to be a date.')
      done()
  
  it 'should validate name is at least 3 characters long', (done) ->
    vdoc = {name: 'bo', number: 0, boolean: true, array: []}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'name needs to be at least 3 characters in length.')
      done()
  
  it 'should validate name is no longer than 12 characters long', (done) ->
    vdoc = {name: 'boromoineinidjsd', number: 0, boolean: true, array: []}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'name needs to be at most 12 characters in length.')
      done()
  
  it 'should validate number is greater than -1', (done) ->
    vdoc = {name: 'boe', number: -3, boolean: true, array: []}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'number needs to be greater than -1.')
      done()
  
  it 'should validate number can be equal to max', (done) ->
    vdoc = {name: 'boe', number: 10, boolean: true, array: [], date: new Date, enum: 'woof'}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ifError(err)
      done()
  
  it 'should validate number is less than or equal to 10', (done) ->
    vdoc = {name: 'brood', number: 13, boolean: true, array: []}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'number needs to be less than or equal to 10.')
      done()
  
  it 'should validate enum is of type enum value', (done) ->
    vdoc = {name: 'boo', number: 2, boolean: false, array: [], date: new Date, enum: 'moocow'}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(err)
      assert.equal(err.message, 'enum must be valid.')
      done()

  it 'should validate defaults are being set', (done) ->
    vdoc = {name: 'boo', number: 2, boolean: false, array: [], date: new Date, enum: 'woof'}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(not err)
      assert.equal(result.default, 'cave')
      done()

  it 'should validate default booleans are being set to false', (done) ->
    vdoc = {name: 'boo', number: 2, boolean: false, array: [], date: new Date, enum: 'woof'}
    wongo.save 'MockValidation', vdoc, (err, result) ->
      assert.ok(not err)
      assert.equal(result.defaultBoolean, false)
      done()

  