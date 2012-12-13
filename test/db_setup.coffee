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
Mock = wongo.schema 'Mock', 
  fields: 
    name: String
    children: [{type: ObjectId, ref: 'Mock'}]
    parent: {type: ObjectId, ref: 'Mock'}
  
  plugins: 
    'example1': plugin_example
    'example2': [plugin_example, {property: 'meow'}]
    
#   hooks: 
#     beforeSave: (document, next) ->
#       console.log 'saving ' + document
#       next()
#     
#     afterSave: (document, next) ->
#     
