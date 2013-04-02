
_ = require 'underscore'
async = require 'async'
mongodb = require 'mongodb'

ObjectID = mongodb.ObjectID

modeler = require __dirname + '/../modeler' 
mongo = require __dirname + '/../mongo'
find = require __dirname + '/find'

#
# Removal functions
#
exports.remove = (_type, documentOrId, callback) ->
  # validate incoming params
  schema = modeler.schema(_type)
  if not callback or not _.isFunction(callback) then throw Error('callback required.')
  if not documentOrId or _.isEmpty(documentOrId) then throw Error('documentOrId required.')
  if _.isString(documentOrId) then _id = documentOrId else document = documentOrId
  # add support for removing multiple documents
  if _.isArray(documentOrId)
    async.each documentOrId, (docOrId, nextInLoop) ->
      exports.remove(_type, docOrId, nextInLoop)
    , (err) -> 
      callback(err)
    return
  # execute middleware and remove
  async.series [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
    (next) -> # if documentOrId is a String then assume _id and load document
      if document then return next()
      find.findById _type, _id, (err, result) ->
        document = result
        next(err)
    (next) -> # run before remove middleware array
      async.eachSeries schema.middleware.beforeRemove, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , (err) ->
        next(err)
    (next) -> # remove
      collection = mongo.collection(_type)
      collection.remove {_id: ObjectID(document._id)}, {w:1}, (err, result) ->
        next(err)
    (next) -> # after remove
      async.eachSeries schema.middleware.afterRemove, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , (err) ->
        delete document._id
        next(err)
  ], callback


#
# The same thing as collection.remove({})
#
exports.clear = (_type, callback) ->
  # validate incoming params
  schema = modeler.schema(_type)
  if not callback or not _.isFunction(callback) then throw Error('callback required.')
  async.series [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
    (next) -> 
      collection = mongo.collection(_type)
      collection.remove {}, {w:1}, (err, result) ->
        next(err, result)
  ], callback