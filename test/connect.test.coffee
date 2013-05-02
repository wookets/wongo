assert = require 'assert'
async = require 'async'
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
  it 'should clear every registered schema', (done) ->
    _types = (_type for own _type of wongo.schemas)
    async.each _types, (_type, nextInLoop) ->
      wongo.clear(_type, nextInLoop)
    , done
