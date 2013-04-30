
_ = require 'underscore'
async = require 'async'
mongodb = require 'mongodb'

ObjectID = mongodb.ObjectID

modeler = require __dirname + '/../modeler' 
mongo = require __dirname + '/../mongo'


#
# Find functions
#
exports.find = (_type, query, callback) ->
  # validate incoming params
  schema = modeler.schema(_type)
  if not callback or not _.isFunction(callback) then throw new Error('callback required.') 
  if not query or not _.isObject(query) then return callback(new Error('query required.')) 
  if not query.where then query = {where: query} # if 'where' isnt present, automatically nest
  documents = []
  async.series [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
    (next) -> # before find middleware
      async.eachSeries schema.middleware.beforeFind, (func, nextInLoop) ->
        func(query, schema, nextInLoop)
      , (err) ->
        next(err)
    (next) -> # execute find
      where = convertWhereForMongo(query.where) # convert _id String to ObjectID (if needed)
      select = convertSelectForMongo(query.select) # convert select statement
      options = {sort: query.sort, limit: query.limit, skip: query.skip} # setup options for query
      collection = mongo.collection(schema.collectionName)
      collection.find(where, select, options).toArray (err, result) ->
        if err then return next(err, result)
        doc._id = String(doc._id) for doc in result when doc._id # support for changing ObjectID into String
        documents = result
        next(null)
    (next) -> # after find middleware
      async.eachSeries schema.middleware.afterFind, (func, nextInLoop) ->
        func(query, schema, documents, nextInLoop)
      , (err) ->
        next(err)
  ], (err) ->
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
# convert ids in where to ObjectID
#
convertWhereForMongo = (where) ->
  if where._id?.$in
    where._id.$in = (new ObjectID(_id) for _id in where._id.$in)
  else if where._id
    where._id = new ObjectID(where._id)
  return where


#
# convert select string to object select (so mongo can understand what we are doing)
#
convertSelectForMongo = (select) ->
  if _.isString(select)
    selectString = select
    fields = select.split(' ')
    select = {}
    for field in fields
      select[field] = true
  return select