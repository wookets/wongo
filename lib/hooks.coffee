
_ = require 'underscore'
mongodb = require 'mongodb'

ObjectID = mongodb.ObjectID


#
# This method will prune (remove) all properties not explicitly defined on the schema.
#
exports.prune = (document, schema, callback) ->
  prune = (document, fields) ->
    for own prop, val of document ? {}
      if prop is '_id' then continue
      meta = fields[prop]
      if not meta               # if property doesnt have a meta, remove it
        delete document[prop]
      else if _.isArray(meta)   # handle array embedded document
        for item in val ? []
          prune(item, meta[0]) if _.isObject(item)
      else if _.isObject(val)           # handle embedded document
        prune(val, meta)
  prune(document, schema.fields)
  callback()

#
# Apply default values to fields if specified.
#
exports.applyDefaults = (document, schema, callback) ->
  applyDefaults = (document, fields) ->
    for own prop, val of document ? {}
      if prop is '_id' then continue
      meta = fields[prop]
      if _.isUndefined(meta) then continue # maybe the dev disabled prune!
      if _.isArray(meta) and meta[0]?.type # array of simple types (e.g. String)
        document[prop] ?= meta[0].default if _.isUndefined(val)
      else if _.isArray(meta) # check array of subdoc types
        applyDefaults(item, meta[0]) for item in val ? []
      else if not meta?.type # check object
        applyDefaults(val, meta)
      else
        document[prop] ?= meta.default if _.isUndefined(val)
  applyDefaults(document, schema.fields)
  callback()

#
# add object _ids
#
exports.generateSubdocIds = (document, schema, callback) ->
  generateSubdocIds = (document, fields) -> # recursive inline function 8P 
    for own prop, val of document
      if prop is '_id' then continue
      if _.isUndefined(document[prop]) then continue
      meta = fields[prop]
      if _.isUndefined(meta) then continue # maybe the dev disabled prune!
      if _.isArray(meta) 
        if not meta[0].type
          for item in document[prop] or []
            document[prop]._id ?= String(ObjectID())
            generateSubdocIds(item, meta[0])
      else if not meta.type
        document[prop]._id ?= String(ObjectID())
        generateSubdocIds(document[prop], meta)
  generateSubdocIds(document, schema.fields)
  callback()
      

#
# Allow a user to run a validation on a document (or partial document)
#
exports.validate = (document, schema, callback) ->
  # validate every field
  if document._id # only validate properties that exist
    for own prop, val of document
      continue if prop is '_id'
      result = validateField(document, prop, schema.fields[prop])
      if _.isString(result) then return callback(Error(result))
  else # validate all properties on schema
    for own field, meta of schema.fields
      if prop is '_id' then continue
      result = validateField(document, field, meta)
      if _.isString(result) then return callback(Error(result))
  callback()

validateField = (document, field, meta) ->
  value = document[field]
  if meta.required and _.isUndefined(value) then return field + ' is required.'
  if _.isArray(meta)
    if meta[0].required and _.isUndefined(value) then return field + ' is required.'
    validateField(field, item, meta[0]) for item in value or []
  else
    switch meta.type
      when String
        if value and not _.isString(value) then return field + ' needs to be a string.'
        if meta.min and value?.length < meta.min then return field + ' needs to be at least ' + meta.min + ' characters in length.'
        if meta.max and value?.length > meta.max then return field + ' needs to be at most ' + meta.max + ' characters in length.'
        if meta.enum and not _.contains(meta.enum, value) then return field + ' must be valid.'
      when Number
        if value and not _.isNumber(value) then return field + ' needs to be a number.'
        if meta.min and value < meta.min then return field + ' needs to be greater than ' + meta.min + '.'
        if meta.max and value > meta.max then return field + ' needs to be less than or equal to ' + meta.max + '.'
      when Boolean
        if value and not _.isBoolean(value) then return field + ' needs to be a boolean.'
      when Date
        if value and not _.isDate(value) then return field + ' needs to be a date.'


#
# load document before remove if necessary
#
# exports.loadDocumentBeforeRemove = (documentOrId, schema, callback) ->
#   loadDocumentBeforeRemove
#     (next) -> # if documentOrId is a String then assume _id and load document
#       if document then return next()
#       crud.findById _type, _id, (err, result) ->
#         document = result
#         next(err)