mongoose = require 'mongoose'
async = require 'async'
_ = require 'underscore'

###
# Easy access mongoose pass thru
###
exports.Schema = Schema = mongoose.Schema

###
# Query operations
###
exports.find = find = (_type, query, callback) ->
  # validate params
  if not _type or not _.isString(_type)
    return callback('InvalidParameter', 'The parameter _type is required.')
  if not query
    return callback('InvalidParamter', 'The parameter query is required.')
  
  Type = mongoose.model(_type)
  mq = Type.find(query.where, query.select, {sort: query.sort, limit: query.limit, skip: query.limit})
  mq.lean()
  mq.exec (err, docs) ->
    # add support for population
    callback(err, docs)

exports.findOne = findOne = (_type, query, callback) ->
  query ?= {}
  query.limit = 1
  find _type, query, (err, result) ->
    if not err and result
      result = result[0]
    callback(err, result)

exports.findById = (_type, _id, callback) ->
  findOne(_type, {where: {_id: _id}}, callback)
    

###
# CRUD operations
###
exports.save = (resource, callback) -> 
  # validate params
  if not resource 
    return callback('InvalidParameter', 'The resource must be a valid object.')
  if not resource._type or not _.isString(resource._type)
    return callback('InvalidParameter', 'The resource must have a valid _type before it can be saved.')
  
  Type = mongoose.model(resource._type)
  # normalize populated references, since it seems to be broken...
  for own key, value of resource  
    if Type.schema.path(key)?.options?.ref # direct object reference
      resource[key] = if _.isObject(value) then value._id else value
    else if Type.schema.path(key)?.options?.type?[0]?.ref # array object reference
      newArray = []
      for val1 in value
        if _.isObject(val1) then newArray.push(val1._id) else newArray.push(val1)
      resource[key] = newArray
  
  # execute
  if resource._id # update
    Type.findById resource._id, (err, doc) ->
      if err then return callback('ResourceNotSaved', err.message)
      for own key2, value of resource # copy in new properties
        if key2 is '_id' then continue
        doc[key2] = value
      doc.save (err) ->
        if callback
          return callback(err, doc?.toObject({getters: true}))
  else # insert
    Type.create resource, (err, doc) ->
      if callback
        return callback(err, doc?.toObject({getters: true}))

exports.update = (_type, where, values, callback) ->
  Type = mongoose.model(_type)
  Type.update(where, values, {multi: true}, callback)
  
  
  