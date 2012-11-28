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
    if not err and result then result = result[0]
    callback(err, result)

###
# Return a single document based on the unique _id.
# @return (err, doc)
###
exports.findById = findById = (_type, _id, callback) ->
  findOne(_type, {where: {_id: _id}}, callback)
    

###
# This will create or update a document.
# @param _type The name of the collection.
# @param
# @return (err, doc)
###
exports.save = (_type, document, callback) -> 
  Type = mongoose.model(_type)
  
  if document._id # update
    update _type, {_id: document._id}, document, (err) ->
      if err then return callback(err)
      findById(_type, document._id, callback) # if someone calls 'save()' return the whole document back to them, otherwise they should call update
  else # insert
    create(_type, document, callback)

exports.create = create = (_type, document, callback) ->
  Type = mongoose.model(_type)
  normalize_populate(Type, document)
  Type.create document, (err, doc) ->
    return callback(err, doc?.toObject({getters: true}))

###
# This will update ALL matching documents if you are not careful.
# @return (err) 
###
exports.update = update = (_type, where, partial_document, callback) ->
  Type = mongoose.model(_type)
  normalize_populate(Type, partial_document)
  Type.update(where, partial_document, {multi: true}, callback)


###
# This will nuke the entire collection' - this method is mainly for supporting test cases
# @return (err) 
###
exports.clear = (_type, callback) ->
  Type = mongoose.model(_type)
  Type.remove({}, callback)
    
# normalize potentially populated references, since default behavior seems to not be as friendly as it should be...
normalize_populate = (Type, document) ->
  for own key, value of document 
    if Type.schema.path(key)?.options?.ref # direct object reference
      if _.isObject(value) and value._id
        document[key] = value._id
    else if Type.schema.path(key)?.options?.type?[0]?.ref # array object reference
      for item in value
        if _.isObject(item) and item._id
          document[key] = item._id

  