wongo = require '../lib/wongo'

Schema = wongo.mongoose.Schema
ObjectId = Schema.ObjectId

db_config = require './db_config.json' # read in your personal database settings
wongo.mongoose.connect(db_config.url) # establish a database connection


# add in Mock models that we can use to test against  
Mock = new Schema
  _type: {type: String, default: 'Mock', required: true}
  name: String
wongo.mongoose.model('Mock', Mock)

MockParent = new Schema
  _type: {type: String, default: 'MockParent', required: true}
  name: String
  children: [{type: ObjectId, ref: 'MockChild'}]
wongo.mongoose.model('MockParent', MockParent)

MockChild = new Schema
  _type: {type: String, default: 'MockChild', require: true}
  name: String
  parent: {type: ObjectId, ref: 'MockParent'}
wongo.mongoose.model('MockChild', MockChild)

