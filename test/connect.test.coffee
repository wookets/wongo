assert = require 'assert'
wongo = require '../lib/wongo'


describe 'Wongo.connect()', ->
  
  #
  # establish connection
  #
  it 'should connect to the database', (done) -> 
    wongo.connect(process.env.DB_URL)
    done()
    
  #
  # clear existing data so we can start fresh
  #
  it 'should clear Mocks', (done) ->
    wongo.clear 'Mock', (err, result) ->
      assert.ifError(err)
      done()
  it 'should clear MockAll', (done) ->
    wongo.clear 'MockAll', (err, result) ->
      assert.ifError(err)
      done()
  it 'should clear MockEmbed', (done) ->
    wongo.clear 'MockEmbed', (err, result) ->
      assert.ifError(err)
      done()
  it 'should clear MockFind', (done) ->
    wongo.clear 'MockFind', (err, result) ->
      assert.ifError(err)
      done()
  it 'should clear MockStrict', (done) ->
    wongo.clear 'MockStrict', (err, result) ->
      assert.ifError(err)
      done()
    
  