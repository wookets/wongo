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
exports.save = (_type, document, callback) ->
  schema = schemas[_type]
  async.series [
    (next) -> # validate incoming params
      if not callback and not _.isFunction(callback) then throw Error('save() - callback required.') 
      if not _type and not _.isString(_type) then return callback(Error('save() - _type required.')) 
      if not document and not _.isObject(document) then return callback(Error('save() - document required.'))
      if not schema then return callback(Error('save() - schema [' + _type + '] not found'))
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
      exports.validate(_type, document, next)
    (next) -> # before save
      next()
    (next) -> # add _id to an subdocs to mimic mongoose
      addObjectIdsToSubDocuments(document, schema.fields)
      next()
    (next) -> # execute save
      collection = db.collection(_type)
      if document._id
        _id = document._id; delete document._id # strip out _id because we are updating
        collection.update {_id: ObjectID(_id)}, {$set: document}, {w:1}, (err, result) ->
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
      if not callback and not _.isFunction(callback) then throw Error('find() - callback required.') 
      if not _type and not _.isString(_type) then return callback(Error('find() - _type required.')) 
      if not query and not _.isObject(query) then return callback(Error('find() - query required.')) 
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


#
# Removal functions
#
exports.remove = (_type, _id, callback) ->
  ifConnected () ->
    collection = db.collection(_type)
    collection.remove({_id: ObjectID(_id)}, {w:1}, callback)

exports.removeAll = (_type, _ids, callback) ->
  async.forEach _ids, (_id, nextInLoop) ->
    exports.remove(_type, _id, nextInLoop)
  , (err) ->
    callback(err)

exports.clear = (_type, callback) ->
  ifConnected () ->
    collection = db.collection(_type)
    collection.remove({}, {w:1}, callback)


#
# Validate
#
exports.validate = (_type, document, callback) ->
  schema = schemas[_type]
  if document._id # only validate properties that exist
    for own prop, val of document
      continue if prop is '_id'
      result = utils.validateField(document, prop, schema.fields[prop])
      if _.isString(result) then return callback(Error(result))
  else # validate all properties on schema
    for own field, meta of schema.fields
      result = utils.validateField(document, field, meta)
      if _.isString(result) then return callback(Error(result))
  callback()



# add object _ids
addObjectIdsToSubDocuments = (document, schema) ->
  for own prop, val of document
    if prop is '_id' then continue
    if _.isUndefined(document[prop]) then continue
    meta = schema[prop]
    if _.isArray(meta) 
      if not meta[0].type
        for item in document[prop] or []
          document[prop]._id ?= String(ObjectID())
          addObjectIdsToSubDocuments(item, meta[0])
    else if not meta.type
      document[prop]._id ?= String(ObjectID())
      addObjectIdsToSubDocuments(document[prop], meta)
    

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

