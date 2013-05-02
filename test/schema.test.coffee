assert = require 'assert'
wongo = require '../lib/wongo'

describe 'Wongo Schema', ->
  
  it 'should change String into type.String', (done) ->    
    schema = wongo.schema 'MockSchema', 
      fields: 
        strictType: String
    assert.equal(schema.fields.strictType.type, String)
    done()
  
  it 'should keep type String', (done) ->    
    schema = wongo.schema 'MockSchema', 
      fields: 
        strictType: {type: String}
    assert.equal(schema.fields.strictType.type, String)
    done()
  
  it 'should change Number into type.Number', (done) ->    
    schema = wongo.schema 'MockSchema', 
      fields: 
        strictType: Number
    assert.equal(schema.fields.strictType.type, Number)
    done()
  
  it 'should keep type Number', (done) ->    
    schema = wongo.schema 'MockSchema', 
      fields: 
        strictType: {type: Number}
    assert.equal(schema.fields.strictType.type, Number)
    done()
  
  it 'should change Date into type.Date', (done) ->    
    schema = wongo.schema 'MockSchema', 
      fields: 
        strictType: Date
    assert.equal(schema.fields.strictType.type, Date)
    done()
  
  it 'should keep type Date', (done) ->    
    schema = wongo.schema 'MockSchema', 
      fields: 
        strictType: {type: Date}
    assert.equal(schema.fields.strictType.type, Date)
    done()
  
  it 'should change Boolean into type.Boolean', (done) ->    
    schema = wongo.schema 'MockSchema', 
      fields: 
        strictType: Boolean
    assert.equal(schema.fields.strictType.type, Boolean)
    done()
  
  it 'should keep type Boolean', (done) ->    
    schema = wongo.schema 'MockSchema', 
      fields: 
        strictType: {type: Boolean}
    assert.equal(schema.fields.strictType.type, Boolean)
    done()