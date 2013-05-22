
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
    saveAll(_type, document, where, callback)
  else
    save(_type, document, where, callback)

saveAll = (_type, documents, where, callback) ->
  async.each documents, (doc, nextInLoop) ->
    exports.save(_type, doc, where, nextInLoop)
  , (err) ->
    callback(err, documents)

save = (_type, document, where, callback) ->
  schema = modeler.schema(_type)
  async.series [
    (next) -> # make sure we are connected to the db
      mongo.ifConnected(next)
    (next) -> # before validate
      async.eachSeries schema.middleware.beforeValidate, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , next
    (next) -> # before save middleware
      async.eachSeries schema.middleware.beforeSave, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , next
    (next) -> # right before save middleware (hide some cleanup stuff from user in these methods)
      async.eachSeries schema.middleware.rightBeforeSave, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , next
    (next) -> # execute save
      collection = mongo.collection(schema.collectionName)
      if not document._id
        collection.insert document, {w:1}, (err, result) ->
          if err then return next(err)
          document._id = result[0]._id
          next()
      else
        whereX = _.clone(where)
        whereX._id = document._id
        delete document._id
        collection.update whereX, {$set: document}, {w:1}, (err) -> # updates allow partial doc saves
          document._id = whereX._id
          next(err)
    (next) -> # run after save middleware array
      async.eachSeries schema.middleware.afterSave, (func, nextInLoop) ->
        func(document, schema, nextInLoop)
      , next
  ], (err) ->
    callback(err, document)