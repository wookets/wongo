
_ = require 'underscore'
async = require 'async'
mongoose = require 'mongoose'
validator = require 'validator'

#
# Mongoose pass thru... these are needed to have wongo control mongoose rather than wongo + your code
exports.mongoose = mongoose

#
# Mongoose connect
exports.connect = (url) ->
  mongoose.connect(url)


# normalize potentially populated references, since default behavior seems to not be as friendly as it should...
normalize_populate = (Type, document) ->
  for own prop, val of document 
    if Type.schema.path(prop)?.options?.ref # direct object reference
      if val?._id
        document[prop] = val._id
    else if Type.schema.path(prop)?.options?.type?[0]?.ref # array object reference
      for item, i in val
        if item?._id
          document[prop][i] = item._id

# this will run 'join' queries when populate is specific in find methods
run_populate_queries = (Type, populate, docs, callback) ->
  if _.isString(populate) then populate = [populate] # string support
  
  async.forEach populate, (prop, nextInLoop) -> # run some async queries to populate our model
    pop_type = Type.schema.path(prop)?.options?.ref # direct object reference
    pop_type ?= Type.schema.path(prop)?.options?.type?[0]?.ref # array object reference
    
    if not pop_type then throw new Error('Populate property ' + prop + ' could not be found on schema.')
    
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
  for own prop, val of updates 
    # ignore the _id because otherwise we get errors 
    if prop is '_id' or prop is 'id' or prop is '_bsontype'
      continue 
    # null means delete from DB, because json undefined = dont include
    else if _.isNull(val) 
      doc[prop] = undefined
    # do a default copy (nothing special)
    else if _.isFunction(val) or _.isString(val) or _.isNumber(val) or _.isDate(val) or _.isBoolean(val) or _.isUndefined(val)
      doc[prop] = val
    # make sure we update array item order
    else if _.isArray(val) 
      doc[prop] = val
      doc.markModified(prop)
    # sub document support
    else if _.isObject(val) 
      return update_properties(doc[prop], val)

# change ObjectID to String so we can compare using standard javascript '===' 
convert_ids_to_string = (doc) ->
  if doc instanceof mongoose.Types.ObjectId
    return String(doc)
  
  if _.isFunction(doc) or _.isString(doc) or _.isNumber(doc) or _.isEmpty(doc) or _.isDate(doc) or _.isUndefined(doc) or _.isBoolean(doc) or _.isNull(val)
    return doc
  
  if _.isArray(doc)
    return (convert_ids_to_string(item) for item in doc)

  if _.isObject(doc) 
    for own prop, val of doc
      doc[prop] = convert_ids_to_string(val)
    return doc
