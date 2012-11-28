mongoose = require 'mongoose'

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

db_config = require './db_config.json' # read in your personal database settings
mongoose.connect(db_config.url) # establish a database connection


# add in Mock models that we can use to test against  
Mock = new Schema
  _type: {type: String, default: 'Mock', required: true}
  name: String
  age: Number
  description: String
  parent: {type: ObjectId, ref: 'MockParent'}
  any: {} 
mongoose.model 'Mock', Mock

MockParent = new Schema
  _type: {type: String, default: 'MockParent', required: true}
  name: String
  children: [{type: ObjectId, ref: 'Mock'}]
mongoose.model 'MockParent', MockParent

MockEmbed = new Schema
  _type: {type: String, default: 'MockEmbed', required: true}
  name: String 
  embed: 
    name: String 
    children: [
      name: String 
    ]
  embeds: [
    name: String 
    child: 
      name: String 
  ]
mongoose.model 'MockEmbed', MockEmbed
