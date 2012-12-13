wongo = require '../lib/wongo'

Schema = wongo.mongoose.Schema
ObjectId = wongo.ObjectId

db_config = require './db_config.json' # read in your personal database settings
wongo.connect(db_config.url) # establish a database connection


# add in Mock models that we can use to test against  
Mock = wongo.schema 'Mock', 
  fields: 
    name: String
  
  #plugins: []
  
#   hooks: 
#     beforeSave: (document, next) ->
#       console.log 'saving ' + document
#       next()
#     
#     afterSave: (document, next) ->
#     

MockParent = wongo.schema 'MockParent',
  fields: 
    name: String
    children: [{type: ObjectId, ref: 'MockChild'}]

MockChild = wongo.schema 'MockChild',
  fields: 
    name: String
    parent: {type: ObjectId, ref: 'MockParent'}

