wongo = require '../lib/wongo'

Schema = wongo.mongoose.Schema

db_config = require './db_config.json' # read in your personal database settings
wongo.connect(db_config.url) # establish a database connection


plugin_example = (schema, options) ->
  property = {}
  property[options?.property or 'woof'] = {type: String}
  schema.add(property)
  

# add in Mock models that we can use to test against  
wongo.schema 'Mock', 
  fields: 
    name: {type: String}
    
    children: [{type: String, ref: 'Mock'}]
    parent: {type: String, ref: 'Mock'}
    
    array: [String]
    embeddedArray: [
      name: String
      array: [String]
      refArray: [{type: String, ref: 'Mock'}]
    ]
    # refs: [{type: ObjectId, ref: 'Mock'}]
    
    beforeSave: {type: String, default: 'not_changed'}
    afterSave: {type: String, default: 'not_changed'}
  
  plugins: 
    'example1': plugin_example
    'example2': [plugin_example, {property: 'meow'}]
    
  hooks:
    beforeSave: (document, next) ->
      document.beforeSave = 'changed'
      next()
    
    afterSave: (document, next) ->
      document.afterSave = 'changed'
      next()

    beforeRemove: (_id, next) ->
      next()
    
    afterRemove: (_id, next) ->
      next()
      