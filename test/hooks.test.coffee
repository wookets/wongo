assert = require 'assert'
wongo = require '../lib/wongo'


describe 'Wongo Schema Hook Override', ->
  
  describe 'Prune', ->
    wongo.schema 'MockHookDisablePrune', 
      fields: 
        name: String
      hooks: 
        prune: false
    it 'should be able to disable prune', (done) ->
      wongo.save 'MockHookDisablePrune', {name: 'Cherry', field2: 'ImSafe'}, (err, result) ->
        assert.ifError(err)
        assert.equal(result.field2, 'ImSafe')
        done()
    it.skip 'should be able to override prune', (done) ->
      done()
  
  describe 'Defaults', ->
    wongo.schema 'MockHookDisableDefaults', 
      fields: 
        name: String
        animal: {type: String, default: 'MooCow'}
      hooks: 
        applyDefaults: false
    it 'should be able to disable defaults', (done) ->
      wongo.save 'MockHookDisableDefaults', {name: 'Snufy'}, (err, result) ->
        assert.ifError(err)
        assert.notEqual(result.animal, 'MooCow')
        done()
    it.skip 'should be able to override defaults', (done) ->
      done()

  describe 'Validate', ->
    wongo.schema 'MockHookDisableValidate', 
      fields: 
        name: {type: String, max: 3}
      hooks: 
        validate: false
    it 'should be able to disable validate', (done) ->
      wongo.save 'MockHookDisableValidate', {name: 'Fetry'}, (err, result) ->
        assert.ifError(err)
        assert.equal(result.name, 'Fetry')
        done()
    it.skip 'should be able to override validate', (done) ->
      done()
      
  describe 'BeforeSave', ->
    wongo.schema 'MockHookUserDefined', 
      fields: 
        name: String
        beforeSave: String
        afterSave: String
      hooks: 
        beforeSave: (document, schema, done) ->
          document.beforeSave = 'meowpants'
          done()
        afterSave: (document, schema, done) ->
          document.afterSave = 'meower'
          done()
    it 'should be able to handle a user defined beforeSave function', (done) ->
      wongo.save 'MockHookUserDefined', {name: 'Fetter'}, (err, result) ->
        assert.ifError(err)
        assert.equal(result.beforeSave, 'meowpants')
        done()
    it 'should be able to handle a user defined afterSave function', (done) ->
      wongo.save 'MockHookUserDefined', {name: 'Fetter'}, (err, result) ->
        assert.ifError(err)
        assert.equal(result.afterSave, 'meower')
        done()
