mongoose = require 'mongoose'
async = require 'async'
_ = require 'underscore'

###
# Easy access mongoose pass thru
###
exports.Schema = Schema = mongoose.Schema

###
# Return a list of documents based on query parameters.
# @return (err, docs)
###
exports.find = find = (_type, query, callback) ->
  Type = mongoose.model(_type)
  mq = Type.find(query.where, query.select, {sort: query.sort, limit: query.limit, skip: query.skip})
  mq.lean()
  mq.exec (err, docs) ->
    # TODO add support for population
    callback(err, docs)

###
# Return a single document based on query paramters.
# @return (err, doc)
###
exports.findOne = findOne = (_type, query, callback) ->
  query ?= {}
  query.limit = 1
  find _type, query, (err, result) ->
    if not err and result
      result = result[0]
    callback(err, result)

###
# Return a single document based on the unique _id.
# @return (err, doc)
###
exports.findById = (_type, _id, callback) ->
  findOne(_type, {where: {_id: _id}}, callback)
    

###
# This will create or findAndUpdate a document.
# @return (err, doc)
###
exports.save = (resource, callback) -> 
  Type = mongoose.model(resource._type)
  
  for own key, value of resource # normalize populated references, since it seems to not be as friendly as it should be...
    if Type.schema.path(key)?.options?.ref # direct object reference
      if _.isObject(value) and value._id
        resource[key] = value._id
    else if Type.schema.path(key)?.options?.type?[0]?.ref # array object reference
      for item in value ? []
        if _.isObject(item) and item._id
          resource[key] = item._id

  if resource._id # update
    Type.findById resource._id, (err, doc) -> # TODO in teh future, let's use findAndModify
      if err then return callback(err)
      doc[key2] = value for own key2, value of resource when key2 isnt '_id' # copy in updated properties
      doc.save (err) ->
        return callback(err, doc?.toObject({getters: true}))
  else # insert
    Type.create resource, (err, doc) ->
      return callback(err, doc?.toObject({getters: true}))
###
# This will update ALL matching documents.
# @return (err) 
###
exports.update = (_type, where, values, callback) ->
  Type = mongoose.model(_type)
  Type.update(where, values, {multi: true}, callback)


###
# This will nuke the entire collection' - this method is mainly for supporting test cases
# @return (err) 
###
exports.clear = (_type, callback) ->
  Type = mongoose.model(_type)
  Type.remove({}, callback)
    

  
  