
_ = require 'underscore'
async = require 'async'
mongodb = require 'mongodb'

ObjectID = mongodb.ObjectID

modeler = require __dirname + '/../modeler' 
mongo = require __dirname + '/../mongo'

#
# Save function
# accepts a full document with or without an _id
# accepts partial documents
# accepts a where constraint to only update if conditions match
#
exports.save = (_type, document, where, callback) ->
  # validate incoming params before doing anything
  schema = modeler.schema(_type)
  if _.isFunction(where) then callback = where; where = {}
  if not callback or not _.isFunction(callback) then throw new Error('callback required.')
  if not document or not _.isObject(document) or _.isEmpty(document) then throw new Error('document required.')
  # add primative support for saving multiple documents
  if _.isArray(document)
    async.each document, (doc, nextInLoop) ->
      exports.save(_type, doc, where, nextInLoop)
    , (err) -> 
      callback(err, document)
    return
  # execute middleware and save
  async.series [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
    (next) -> # before save middleware
      async.eachSeries schema.middleware.beforeSave, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , (err) ->
        next(err)
    (next) -> # execute save
      collection = mongo.collection(_type)
      if not document._id
        collection.insert document, {w:1}, (err, result) ->
          document._id = String(result[0]._id)
          next(err)
      else 
        _id = ObjectID(document._id)
        where._id = _id
        delete document._id
        collection.update where, {$set: document}, {safe: true, w:1}, (err) ->
          document._id = String(_id)
          next(err)
    (next) -> # run after save middleware array
      async.eachSeries schema.middleware.afterSave, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , (err) ->
        next(err)
  ], (err) ->
    callback(err, document)