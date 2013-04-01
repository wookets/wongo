
_ = require 'underscore'
async = require 'async'
mongodb = require 'mongodb'

ObjectID = mongodb.ObjectID

hooks = require __dirname + '/hooks'
modeler = require __dirname + '/modeler' 
mongo = require __dirname + '/mongo'
populate = require __dirname + '/populate'


#
# Save function
# accepts a full document with or without an _id
# accepts partial documents
# accepts a where constraint to only update if conditions match
#
exports.save = (_type, document, where, callback) ->
  if _.isFunction(where) then callback = where; where = {}
  # add primative support for saving multiple documents
  if _.isArray(document)
    async.each document, (doc, nextInLoop) ->
      exports.save(_type, doc, where, nextInLoop)
    , (err) -> 
      callback(err, document)
    return
  # validate incoming params before doing anything
  schema = modeler.schema(_type)
  if not callback or not _.isFunction(callback) then throw Error('callback required.')
  if not document or not _.isObject(document) or _.isEmpty(document) then throw Error('document required.')
  # execute middleware and save
  async.series [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
    (next) -> # run before save middleware array
      async.eachSeries schema.middleware.beforeSave, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , (err) ->
        next(err)
    (next) -> # execute save
      collection = mongo.collection(_type)
      if not document._id
        collection.insert document, (err, result) ->
          document._id = String(result[0]._id)
          next(err)
      else 
        where._id = ObjectID(document._id); delete document._id
        collection.update where, {$set: document}, {safe: true}, (err) ->
          document._id = String(where._id)
          next(err)
    (next) -> # run after save middleware array
      async.eachSeries schema.middleware.afterSave, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , (err) ->
        next(err)
  ], (err) ->
    callback(err, document)


#
# Find functions
#
exports.find = (_type, query, callback) ->
  # validate incoming params
  schema = modeler.schema(_type)
  if not callback or not _.isFunction(callback) then throw Error('callback required.') 
  if not query or not _.isObject(query) then return callback(Error('query required.')) 
  if not query.where then query = {where: query} # if 'where' isnt present, automatically nest
  async.waterfall [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
    (next) -> # before find
      before = schema.hooks?.find?.before
      if _.isFunction(before) then return before(query, next)
      next()
    (next) -> # execute find
      convertIdsInWhere(query.where) # convert _id String to ObjectID (if needed)
      options = {sort: query.sort, limit: query.limit, skip: query.skip} # setup options for query
      collection = mongo.collection(_type)
      collection.find(query.where, query.select, options).toArray (err, result) ->
        if err then return next(err, result)
        doc._id = String(doc._id) for doc in result when doc._id # support for changing ObjectID into String
        next(null, result)
    (documents, next) -> # execute any populates
      return run_populate_queries(schema.fields, query.populate, documents, next) if query.populate # support for populate
      next(null, documents)
    (documents, next) -> # after find
      after = schema.hooks?.find?.after
      if _.isFunction(after) then return after(documents, next)
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
  # validate incoming params
  schema = modeler.schema(_type)
  if not callback or not _.isFunction(callback) then throw Error('callback required.')
  if not documentOrId or _.isEmpty(documentOrId) then throw Error('documentOrId required.')
  if _.isString(documentOrId) then _id = documentOrId else document = documentOrId
  async.series [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
    (next) -> # if documentOrId is a String then assume _id and load document
      if document then return next()
      exports.findById _type, _id, (err, result) ->
        document = result
        next(err)
    (next) -> # run before remove middleware array
      async.eachSeries schema.middleware.beforeRemove, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , (err) ->
        next(err)
    (next) -> # remove
      collection = mongo.collection(_type)
      collection.remove {_id: document.id}, {w:1}, (err, result) ->
        next(err)
    (next) -> # after remove
      async.eachSeries schema.middleware.afterRemove, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , (err) ->
        next(err)
  ], callback

exports.removeAll = (_type, documentsOrIds, callback) ->
  # validate incoming params
  schema = modeler.schema(_type)
  if not callback or not _.isFunction(callback) then throw Error('callback required.')
  if not documentsOrIds or not _.isArray(documentsOrIds) or _.isEmpty(documentsOrIds) then throw Error('documentsOrIds required.')
  async.waterfall [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
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
  # validate incoming params
  schema = modeler.schema(_type)
  if not callback or not _.isFunction(callback) then throw Error('callback required.')
  async.series [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
    (next) -> 
      collection = mongo.db.collection(_type)
      collection.remove {}, {w:1}, (err, result) ->
        next(err, result)
  ], callback


#
# convert ids in where to ObjectID
#
convertIdsInWhere = (where) ->
  if where._id?.$in
    where._id.$in = (ObjectID(_id) for _id in where._id.$in)
  else if where._id
    where._id = ObjectID(where._id)


#
# Pop queries
#
run_populate_queries = (schema, populate, docs, callback) ->
  if _.isString(populate) then populate = [populate] # string support
  #console.log 'pop'
  #console.log schema
  async.forEach populate, (pop, nextInLoop) -> # run some async queries to populate our model
    #console.log pop
    pop_type = null
    pop_prop = null
    for prop, val of schema or {}
      #console.log val
      if _.isArray(val) 
        if val[0].populateAlias is pop 
          pop_type = val[0].ref
          pop_prop = prop
      else
        if val.populateAlias is pop 
          pop_type = val.ref
          pop_prop = prop
    
    #console.log pop_type
    if not pop_type then throw new Error('Populate property ' + pop + ' could not be found on schema.')
    
    # we need to pull out the _id from each doc that was returned
    _ids = []
    for doc in docs
      if _.isArray(doc[pop_prop])
        _ids = _.union(doc[pop_prop], _ids)
      else 
        _ids.push(doc[pop_prop])
    
    # we need to query for each pop type based on assembled _ids
    exports.find pop_type, {where: {_id: {$in: _ids}}}, (err, pop_docs) ->
      if err then return nextInLoop(err)
      for doc in docs # assign back to doc 
        for pop_doc in pop_docs
          if _.isArray(doc[pop_prop])
            for item, i in doc[pop_prop]
              if pop_doc._id is item
                doc[pop] ?= []
                doc[pop][i] = pop_doc
          else
            if String(pop_doc._id) is String(doc[pop_prop])
              doc[pop] = pop_doc
      #console.log docs
      nextInLoop()  
  , (err) ->
    callback(err, docs)

findPopReference = (pop, schema) ->
  for prop, val in schema or {}
    if _.isArray(val) 
      if val[0].populateAlias is pop then return val[0].ref
    else
      if val.populateAlias is pop then return val.ref
  
  