
mongodb = require 'mongodb'
ObjectID = mongodb.ObjectID
_ = require 'underscore'

#
# Convert all Strings to ObjectIDs if defined on the schema as such
#
exports.beforeSave = (document, schema, callback) ->
  convert = (doc, fields) -> # inline function to allow us to recurse SubDoc types
    for own property, value of doc
      meta = fields[property]
      if not meta and property isnt '_id' then continue # maybe the user disabled prune
      if _.isArray(meta) # if array, unwrap
        meta = meta[0]
      if property is '_id' or meta.type is ObjectID # convert known ObjectIDs
        if _.isArray(value)
          doc[property] = (new ObjectID(id) for id in value when _.isString(id))
        else
          doc[property] = new ObjectID(value) if _.isString(value)
      else if meta.type is 'SubDoc'
        if _.isArray(value)
          convert(val, meta) for val in value
        else
          convert(value, meta)
  convert(document, schema.fields)
  callback()

#

# Convert all ObjectIDs to Strings
#
exports.afterSave = (document, schema, callback) ->
  convertDocOID2String(document)
  callback()


#
# Convert all Strings to ObjectIDs if defined on the schema as such
#
exports.beforeFind = (query, schema, callback) ->
  for own property, condition of query.where
    meta = schema.fields[property]
    if _.isArray(meta) # if array, unwrap
      meta = meta[0]
    if property is '_id' or meta.type is ObjectID # convert known ObjectIDs
      if condition?.$in # support $in finding of multiple _ids
        condition.$in = (new ObjectID(id) for id in condition.$in when _.isString(id))
      else # normal equals support
        query.where[property] = new ObjectID(condition) if _.isString(condition)
  callback()


#
# Convert all ObjectIDs to Strings
#
exports.afterFind = (query, schema, documents, callback) ->
  for doc in documents
    convertDocOID2String(doc)
  callback()


#
# Util method used to determine if a javascript object is an ObjectID. This is based on the mongodb driver.
#
isObjectID = (val) ->
  if val?._bsontype is 'ObjectID'
    return true
  else
    return false

isSubDoc = (val) ->
  if _.isString(val) or _.isDate(val) or _.isNumber(val) or _.isUndefined(val) or _.isNull(val) or _.isArray(val) or _.isBoolean(val) or isObjectID(val)
    return false
  else if _.isObject(val)
    return true
  else
    return false

convertDocOID2String = (doc) ->
  for own prop, val of doc
    if _.isArray(val) # handle arrays
      for item, i in val
        if isObjectID(item)
          doc[prop][i] = String(item)
        else if isSubDoc(item)
          convertDocOID2String(item)
    else if isObjectID(val)
      doc[prop] = String(val)
    else if isSubDoc(val) # handle nested documents
      convertDocOID2String(val)