_ = require 'underscore'
async = require 'async'
mongoose = require 'mongoose'

#
# Mongoose pass thru... these are needed to have wongo control mongoose rather than wongo + your code
#
exports.mongoose = mongoose
exports.ObjectId = mongoose.Schema.ObjectId

#
# Mongoose connect
exports.connect = (url) ->
  mongoose.connect(url)

# 
# Mongoose schema replacement
exports.schema = (_type, wschema) ->
  wschema.fields._type = {type: String, default: _type, required: true}
  Schema = new mongoose.Schema(wschema.fields)
  
  # hooks
  Schema.statics.beforeSave = wschema.hooks?.beforeSave
  Schema.statics.afterSave = wschema.hooks?.afterSave
  
  for own name, plugin of wschema.plugins ? {} # plugins
    if _.isArray(plugin) then Schema.plugin(plugin[0], plugin[1]) else Schema.plugin(plugin)
    
  mongoose.model(_type, Schema)

#
# Return a list of documents based on query parameters.
# @return (err, docs)
#
exports.find = find = (_type, query, callback) ->
  Type = mongoose.model(_type)
  mq = Type.find(query.where, query.select, {sort: query.sort, limit: query.limit, skip: query.skip})
  mq.lean()
  mq.exec (err, docs) ->
    if query.populate # support for populate
      run_populate_queries(Type, query.populate, docs, callback)
    else
      callback(err, docs)

#
# Return a single document based on query paramters.
# @return (err, doc)
#
exports.findOne = findOne = (_type, query, callback) ->
  query ?= {}
  query.limit = 1
  find _type, query, (err, result) ->
    if not err and result then result = result[0]
    callback(err, result)

#
# Return a single document based on the unique _id.
# @return (err, doc)
#
exports.findById = findById = (_type, _id, callback) ->
  findOne(_type, {where: {_id: _id}}, callback)

# ### Count
# @param _type - String
# @param where - Object
# @return (err, num) 
exports.count = count = (_type, where, callback) ->
  Type = mongoose.model(_type)
  Type.count where, (err, num) ->
    return callback(err, num)

#  
# Will save a document to the database. Save will always return the most recent document from the database
# after it has been created or updated. 
#
exports.save = save = (_type, document, callback) -> 
  Type = mongoose.model(_type)
  
  normalize_populate(Type, document)
  
  saved_document = null
  
  async.series [
    (next) -> # call before save
      if not Type.beforeSave then return next()
      Type.beforeSave(document, next)
      
    (next) -> # call save
      if document._id # update
        Type.findById document._id, (err, doc) ->
          if err then return callback(err)
          update_properties(doc, document)
          doc.save (err) ->
            saved_document = doc?.toObject({getters: true})
            next(err)
      else # insert
        Type.create document, (err, doc) ->
          saved_document = doc?.toObject({getters: true})
          next(err)
      
    (next) -> # call after save
      if not Type.afterSave then return next()
      Type.afterSave(saved_document, next)
      
  ], (err) ->
    callback(err, saved_document)

#
# Uses the save method in an async parallel fashion, but will not return until all have been saved.
#
exports.saveAll = saveAll = (_type, documents, callback) ->
  saved_docs = []
  async.forEach documents, (document, nextInLoop) ->
    save _type, document, (err, doc) ->
      saved_docs.push(doc)
      nextInLoop(err)
  , (err) ->
    callback(err, saved_docs)

exports.create = create = (_type, document, callback) ->
  Type = mongoose.model(_type)
  normalize_populate(Type, document)
  saved_document = null
  async.series [
    (next) -> # call before create
      if not Type.beforeCreate then return next()
      Type.beforeCreate(document, next)
    
    (next) -> # call remove
      Type.create document, (err, doc) ->
        saved_document = doc?.toObject({getters: true})
        next(err)
      
    (next) -> # call after remove
      if not Type.afterCreate then return next()
      Type.afterCreate(saved_document, next)
  
  ], (err) ->
    callback(err)

exports.update = update = (_type, where, partial_document, callback) ->
  Type = mongoose.model(_type)
  normalize_populate(Type, partial_document)
  Type.update(where, partial_document, {multi: true}, callback)
  

exports.remove = remove = (_type, _id, callback) ->
  Type = mongoose.model(_type)
  
  async.series [
    (next) -> # call before remove
      if not Type.beforeRemove then return next()
      Type.beforeRemove(_id, next)
    
    (next) -> # call remove
      Type.findByIdAndRemove(_id, next)
      
    (next) -> # call after remove
      if not Type.afterRemove then return next()
      Type.afterRemove(_id, next)
    
  ], (err) ->
    callback(err)
  
  

exports.removeAll = removeAll = (_type, _ids, callback) ->
  async.forEach _ids, (_id, nextInLoop) ->
    remove(_type, _id, nextInLoop)
  , callback

#
# This will nuke the entire collection' - this method is mainly for supporting test cases
# @return (err) 
#
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
      for item, i in value
        if _.isObject(item) and item._id
          document[key][i] = item._id

run_populate_queries = (Type, populate, docs, callback) ->
  if _.isString(populate) then populate = [populate] # string support
  
  async.forEach populate, (prop, nextInLoop) -> # run some async queries to populate our model
    pop_type = Type.schema.path(prop)?.options?.ref # direct object reference
    pop_type ?= Type.schema.path(prop)?.options?.type?[0]?.ref # array object reference
    
    # we need to pull out the _id from each doc that was returned
    _ids = []
    for doc in docs
      if _.isArray(doc[prop])
        _ids = _.union(doc[prop], _ids)
      else 
        _ids.push(doc[prop])
    
    # we need to query for each pop type based on assembled _ids
    find pop_type, {where: {_id: {$in: _ids}}}, (err, pop_docs) ->
      if err then return nextInLoop(err)
    
      for doc in docs # assign back to doc 
        for pop_doc in pop_docs
          if _.isArray(doc[prop])
            for item, i in doc[prop]
              if String(pop_doc._id) is String(item)
                doc[prop][i] = pop_doc
          else
            if String(pop_doc._id) is String(doc[prop])
              doc[prop] = pop_doc
      nextInLoop()
      
  , (err) ->
    callback(err, docs)

# copy any updates (properties that exist) to the doc, if null set to undefined (remove from DB)
update_properties = (doc, updates) ->
  for own prop, val of updates # copy in new properties
    if prop is '_id' or prop is 'id' or prop is '_bsontype'
      continue # ignore these properties
    if _.isArray(val) 
      doc.markModified(prop) # make sure we update array item order
    else if _.isDate(val)
      # do nothing
    else if _.isObject(val) 
      return update_properties(doc[prop], val) # sub document support

    if val is null
      doc[prop] = undefined # null means delete from DB, because json undefined = dont include
    else
      doc[prop] = val
  