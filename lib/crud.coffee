#
# Find
#

#
# Return a list of documents based on query parameters.
# @return (err, docs)
exports.find = find = (_type, query, callback) ->
  Type = mongoose.model(_type)
  
  query ?= {}
  if not query.where # if 'where' isnt present, automatically nest
    query = {where: query}

  async.waterfall [
    (next) -> # call beforeFind(query) hook
      if Type.beforeFind then Type.beforeFind(query, next) else next()
      
    (next) -> # execute find
      mq = Type.find(query.where, query.select, {sort: query.sort, limit: query.limit, skip: query.skip})
      mq.lean()
      mq.exec (err, docs) ->
        if err then return callback(err)
        convert_ids_to_string(doc) for doc in docs # support for changing ObjectID into String
        return run_populate_queries(Type, query.populate, docs, next) if query.populate # support for populate
        next(err, docs)
    
    (docs, next) -> # call afterFind(query, docs) hook
      if Type.afterFind then Type.afterFind(docs, next) else next(null, docs)
      
  ], (err, docs) ->
    callback(err, docs) 

#
# Return a single document based on query paramters.
# @return (err, doc)
exports.findOne = findOne = (_type, query, callback) ->
  query ?= {}
  if not query.where # if 'where' isnt present, automatically nest
    query = {where: query}
  query.limit = 1
  find _type, query, (err, result) ->
    if not err and result then result = result[0]
    callback(err, result)

#
# Return a single document based on the unique _id.
# @return (err, doc)
exports.findById = findById = (_type, _id, callback) ->
  findOne(_type, {where: {_id: _id}}, callback)

# 
# Count
# @param _type - String
# @param where - Object
# @return (err, num) 
exports.count = count = (_type, where, callback) ->
  Type = mongoose.model(_type)
  Type.count(where, callback)


#
# Save
#

#  
# Will save a document to the database. Save will always return the most recent document from the database
# after it has been created or updated. 
exports.save = save = (_type, document, callback) -> 
  Type = mongoose.model(_type)
  document._type ?= _type
  
  normalize_populate(Type, document)
  
  async.waterfall [
    (next) -> # call before save
      if Type.beforeSave then Type.beforeSave(document, next) else next()
      
    (next) -> # call save
      if document._id # update
        Type.findById document._id, (err, doc) ->
          if err then return callback(err)
          update_properties(doc, document)
          doc.save (err) ->
            saved_document = doc?.toObject({getters: true})
            convert_ids_to_string(saved_document)
            next(err, saved_document)
      else # insert
        Type.create document, (err, doc) ->
          saved_document = doc?.toObject({getters: true})
          convert_ids_to_string(saved_document)
          next(err, saved_document)
      
    (saved_document, next) -> # call after save
      if Type.afterSave then Type.afterSave(saved_document, (err) -> next(err, saved_document)) else next(null, saved_document)
      
  ], (err, saved_document) ->
    callback(err, saved_document)

#
# Uses the save method in an async parallel fashion, but will not return until all have been saved.
exports.saveAll = saveAll = (_type, documents, callback) ->
  saved_docs = []
  async.forEach documents, (document, nextInLoop) ->
    save _type, document, (err, doc) ->
      saved_docs.push(doc)
      nextInLoop(err)
  , (err) ->
    callback(err, saved_docs)

#
# This is very helpful in place of attempting to use a saveAll for efficiency and accuracy
exports.update = update = (_type, where, partial_document, callback) ->
  Type = mongoose.model(_type)
  normalize_populate(Type, partial_document)
  Type.update(where, partial_document, {multi: true}, callback)

 
#
# Remove
#
exports.remove = remove = (_type, _id, callback) ->
  Type = mongoose.model(_type)
  async.series [
    (next) -> # call before remove
      if Type.beforeRemove then Type.beforeRemove(_id, next) else next()
    (next) -> # call remove
      Type.findByIdAndRemove(_id, next)
    (next) -> # call after remove
      if Type.afterRemove then Type.afterRemove(_id, next) else next()
  ], (err) ->
    callback(err)

exports.removeAll = removeAll = (_type, _ids, callback) ->
  async.forEach _ids, (_id, nextInLoop) ->
    remove(_type, _id, nextInLoop)
  , callback

#
# This will nuke the entire collection' - this method is mainly for supporting test cases
# @return (err) 
exports.clear = (_type, callback) ->
  Type = mongoose.model(_type)
  Type.remove({}, callback)