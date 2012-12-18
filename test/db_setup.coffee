wongo = require '../lib/wongo'

Schema = wongo.mongoose.Schema
ObjectId = wongo.ObjectId

db_config = require './db_config.json' # read in your personal database settings
wongo.connect(db_config.url) # establish a database connection


plugin_example = (schema, options) ->
  property = {}
  property[options?.property or 'woof'] = {type: String}
  schema.add(property)
  

# add in Mock models that we can use to test against  
wongo.schema 'Mock', 
  fields: 
    name: String
    
    children: [{type: ObjectId, ref: 'Mock'}]
    parent: {type: ObjectId, ref: 'Mock'}
    
    array: [String]
    # refs: [{type: ObjectId, ref: 'Mock'}]
    
    beforeSave: {type: String, default: 'not_changed'}
    afterSave: {type: String, default: 'not_changed'}
    beforeCreate: {type: String, default: 'not_changed'}
    afterCreate: {type: String, default: 'not_changed'}
    beforeUpdate: {type: String, default: 'not_changed'}
    afterUpdate: {type: String, default: 'not_changed'}
    beforeRemove: {type: String, default: 'not_changed'}
    afterRemove: {type: String, default: 'not_changed'}
  
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

    beforeCreate: (document, next) ->
      document.beforeCreate = 'changed'
      next()
    
    afterCreate: (document, next) ->
      document.afterCreate = 'changed'
      next()
      
    beforeUpdate: (document, next) ->
      document.beforeUpdate = 'changed'
      next()
    
    afterUpdate: (document, next) ->
      document.afterUpdate = 'changed'
      next()
    
    beforeRemove: (_id, next) ->
      next()
    
    afterRemove: (_id, next) ->
      next()
      