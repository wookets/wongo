#
# Lib module for managing the connection to the database. 
#

_ = require 'underscore'
mongodb = require 'mongodb'

MongoClient = mongodb.MongoClient

#
# Keep our db client handle handy
#
exports.db = null


#
# Establish a connection to the database
#
exports.connect = (url) ->
  MongoClient.connect url, (err, opened_db) ->
    if err then throw err
    exports.db = opened_db
    return


#
# delay the query until a connection is established 
#
exports.ifConnected = (callback) ->
  if exports.db then return callback()
  attempts = 0
  waitForDb = setInterval () -> 
    if exports.db 
      clearInterval(waitForDb)
      callback()
    else if attempts is 20 # after 5 seconds a waiting, tell user to connect()
      clearInterval(waitForDb)
      return callback(new Error('We waited and waited but the database is no where to be found. Did you use connect(url)?'))
    else
      attempts += 1
  , 250 # recheck every 250ms
  return

#
# Collection
#
exports.collection = (_type) ->
  if not _type or not _.isString(_type) then throw new Error('_type required.')
  return exports.db.collection(_type)
