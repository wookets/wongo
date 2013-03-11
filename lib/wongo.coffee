_ = require 'underscore'
async = require 'async'
mongodb = require 'mongodb'

utils = require './utils'

MongoClient = mongodb.MongoClient
ObjectID = mongodb.ObjectID


#
# Connection
#
db = null
exports.connect = (url) ->
  MongoClient.connect process.env.DB_URL, (err, opened_db) ->
    if err then throw err
    db = opened_db


#
# Schema
#
schemas = {}
exports.schema = (_type, schema) ->
  # normalize schema 
  utils.normalizeSchema(schema.fields)
  # register schema
  schemas[_type] = schema
  # plugin support
  utils.applyPlugins(schema)
  # ensure indexes
  for index in schema.indexes ? []
    ifConnected () ->
      if _.isArray(index) 
        db.ensureIndex(_type, index[0], index[1], (err, result) -> if err then throw err)
      else 
        db.ensureIndex(_type, index, (err, result) -> if err then throw err)
  
  return schema


#
# Save functions
#
exports.save = (_type, document, where, callback) ->
  schema = schemas[_type]
  async.series [
    (next) -> # validate incoming params
      if _.isFunction(where) and _.isUndefined(callback) then callback = where
      if not callback or not _.isFunction(callback) then throw Error('callback required.') 
      if not _type or not _.isString(_type) then return callback(Error('_type required.')) 
      if not schemas[_type] then return callback(Error('_type [' + _type + '] not recognized'))
      if not document or not _.isObject(document) or _.isEmpty(document) then return callback(Error('document required.'))
      next()
    (next) -> # make sure we are connected to the db
      ifConnected(next)
    (next) -> # prune extra fields from document
      utils.prune(document, schema.fields)
      next()
    (next) -> # set any default values
      if not document._id then utils.applyDefaults(document, schema.fields) # set default properties if not set
      next()
    (next) -> # validate document
      err = utils.validate(document, schema.fields)
      next(err)
    (next) -> # before save
      next()
    (next) -> # add _id to an subdocs to mimic mongoose
      utils.addObjectIdsToSubDocuments(document, schema.fields)
      next()
    (next) -> # execute save
      collection = db.collection(_type)
      if document._id
        _id = document._id
        delete document._id # strip out _id because we are updating
        where ?= {}
        where._id = ObjectID(_id) # force update on _id
        update = {$set: document} # force wrap in a $set operation
        unset = {} # unset null values from the database... we don't store nulls
        unset[prop] = '' for own prop, val of document if _.isNull(val)
        update.unset = {$unset: unset} if not _.isEmpty(unset)
        collection.update where, update, {w:1}, (err, result) ->
          document._id = _id
          next(err)
      else
        collection.insert document, {w:1}, (err, result) ->
          document._id = String(result[0]._id)
          next(err)
    (next) -> # after save
      next()
  ], (err) ->
    callback(err, document)

exports.saveAll = (_type, documents, callback) ->  
  async.forEach documents, (document, nextInLoop) ->
    exports.save(_type, document, nextInLoop)
  , (err) ->
    callback(err, documents)


#
# Find functions
#
exports.find = (_type, query, callback) ->
  async.waterfall [
    (next) -> # validate incoming params
      if not callback or not _.isFunction(callback) then throw Error('callback required.') 
      if not _type or not _.isString(_type) then return callback(Error('_type required.')) 
      if not schemas[_type] then return callback(Error('_type [' + _type + '] not recognized'))
      if not query or not _.isObject(query) then return callback(Error('query required.')) 
      if not query.where then query = {where: query} # if 'where' isnt present, automatically nest
      next()
    (next) -> # make sure we are connected to the db
      ifConnected(next)
    (next) -> # before find
      next()
    (next) -> # execute find
      collection = db.collection(_type)
      convertStringToId(query.where)
      options = {sort: query.sort, limit: query.limit, skip: query.skip}
      collection.find(query.where, query.select, options).toArray (err, result) ->
        if err then return next(err, result)
        convertIdsToString(result) # support for changing ObjectID into String
        next(null, result)
    (documents, next) -> # after find
      next(null, documents)
  ], (err, documents) ->
    callback(err, documents)

exports.findOne = (_type, query, callback) ->
  if not query.where then query = {where: query} # if 'where' isnt present, automatically nest
  query.limit = 1
  exports.find _type, query, (err, result) ->
    callback(err, result?[0])

exports.findById = (_type, _id, callback) ->
  exports.findOne(_type, {_id: _id}, callback)

exports.findByIds = (_type, _ids, callback) ->
  exports.find(_type, {_id: {$in: _ids}}, callback) 


#
# Removal functions
#
exports.remove = (_type, documentOrId, callback) ->
  async.waterfall [
    (next) -> # validate incoming params
      if not callback or not _.isFunction(callback) then throw Error('callback required.') 
      if not _type or not _.isString(_type) then return callback(Error('_type required.'))
      if not schemas[_type] then return callback(Error('_type [' + _type + '] not recognized'))
      if not documentOrId or _.isEmpty(documentOrId) then return callback(Error('documentOrId required.'))
      next()
    (next) -> # make sure we are connected to the db
      ifConnected(next)
    (next) -> # if documentOrId is a String then assume _id and load document
      if _.isString(documentOrId)
        exports.findById(_type, documentOrId, next)
      else
        next(null, documentOrId)
    (document, next) -> # before remove
      next(null, document) 
    (document, next) -> # remove
      collection = db.collection(_type)
      collection.remove {_id: document.id}, {w:1}, (err, result) ->
        next(err, document)
    (document, next) -> # after remove
      next()
  ], callback

exports.removeAll = (_type, documentsOrIds, callback) ->
  async.waterfall [
    (next) -> # validate incoming params
      if not callback or not _.isFunction(callback) then throw Error('callback required.') 
      if not _type or not _.isString(_type) then return callback(Error('_type required.'))
      if not schemas[_type] then return callback(Error('_type [' + _type + '] not recognized'))
      if not documentsOrIds or not _.isArray(documentsOrIds) or _.isEmpty(documentsOrIds) then return callback(Error('documentsOrIds required.'))
      next()
    (next) -> # make sure we are connected to the db
      ifConnected(next)
    (next) -> # if documentOrIds is a String Array then assume _ids and load documents
      if _.isString(documentsOrIds[0])
        _ids = (_id for _id in documentOrIds when _.isString(_id))
        exports.findByIds(_type, _ids, next)
      else
        next(null, documentsOrIds)
    (documents, next) ->  
      async.forEach documents, (document, nextInLoop) ->
        exports.remove(_type, document, nextInLoop)
      , next
  ], callback

exports.clear = (_type, callback) ->
  async.series [
    (next) -> # validate incoming params
      if not callback or not _.isFunction(callback) then throw Error('callback required.') 
      if not _type or not _.isString(_type) then return callback(Error('_type required.'))
      if not schemas[_type] then return callback(Error('_type [' + _type + '] not recognized'))
      next()
    (next) -> # make sure we are connected to the db
      ifConnected(next)
    (next) -> 
      collection = db.collection(_type)
      collection.remove {}, {w:1}, (err, result) ->
        next(err, result)
  ], callback
    


#
# delay the query until a connection is established 
#
ifConnected = (callback) ->
  if db then return callback()
  attempts = 0
  waitForDb = setInterval () -> 
    if db 
      clearInterval(waitForDb)
      callback()
    else if attempts is 20 # after 5 seconds a waiting, tell user to connect()
      clearInterval(waitForDb)
      return callback(Error('We waited and waited but the database is no where to be found. Did you use connect(url)?'))
    else
      attempts += 1
  , 250


#  
# change ObjectID to String so we can compare using standard javascript '===' 
#
convertIdsToString = (doc) ->
  if doc instanceof ObjectID
    return String(doc)
  if _.isFunction(doc) or _.isString(doc) or _.isNumber(doc) or _.isEmpty(doc) or _.isDate(doc) or _.isUndefined(doc) or _.isBoolean(doc) or _.isNull(val)
    return doc
  if _.isArray(doc)
    return (convertIdsToString(item) for item in doc)
  if _.isObject(doc) 
    for own prop, val of doc
      doc[prop] = convertIdsToString(val)
    return doc

convertStringToId = (where) ->
  if where._id?.$in
    where._id.$in = (ObjectID(_id) for _id in where._id.$in)
  else if where._id
    where._id = ObjectID(where._id)

