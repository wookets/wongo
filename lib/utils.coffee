_ = require 'underscore'
async = require 'async'
mongodb = require 'mongodb'

ObjectID = mongodb.ObjectID

#
# This will convert schema property types; e.g. String becomes {type: String}
# This will recurse the documents and do all subdocuments and arrays
#
exports.normalizeSchema = normalizeSchema = (schema) ->
  for own field, meta of schema
    if _.isArray(meta) 
      switch meta[0] 
        when String, Number, Boolean, Date then schema[field][0] = {type: meta[0]}
      if not schema[field][0].type then normalizeSchema(meta[0])
    else if not meta.type
      switch meta
        when String, Number, Boolean, Date then schema[field] = {type: meta}
        else normalizeSchema(meta)


#
# This method will call any passed in plugins, which are just functions that receive the schema and any options
#
exports.applyPlugins = (schema) ->
  for plugin in schema.plugins ? []
    if _.isArray(plugin) # [function, args]
      plugin[0](schema, plugin[1])
    else # [function]
      plugin(schema)


#
# This method will prune (remove) all properties not explicitly defined on the schema.
#
exports.prune = prune = (document, schema) ->
  for own prop, val of document
    if not schema[prop] then delete document[prop]
    else if _.isArray(schema[prop]) # handle array embedded document
      for item in val or [] 
        if _.isObject(item) then prune(item, schema[prop][0]) 
    else if _.isObject(val) # handle embedded document
      prune(val, schema[prop])


#
# Apply default values to fields if specified.
#
exports.applyDefaults = applyDefaults = (document, schema) ->
  for own prop, val of document
    meta = schema[prop]
    if _.isArray(meta) and not meta[0]?.type # check array
      for item in val or []
        applyDefaults(item, meta[0])
    else if not meta.type # check object
      applyDefaults(val, meta)
    else
      if not _.isUndefined(val) then continue 
      default_value = if _.isArray(meta) then meta[0].default else meta.default
      document[prop] ?= default_value


#
# Validate
#
exports.validate = (document, schema) ->
  if document._id # only validate properties that exist
    for own prop, val of document
      continue if prop is '_id'
      result = validateField(document, prop, schema[prop])
      if _.isString(result) then return Error(result)
  else # validate all properties on schema
    for own field, meta of schema
      result = validateField(document, field, meta)
      if _.isString(result) then return Error(result)

exports.validateField = validateField = (document, field, meta) ->
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
# add object _ids
#
exports.addObjectIdsToSubDocuments = addObjectIdsToSubDocuments = (document, schema) ->
  for own prop, val of document
    if prop is '_id' then continue
    if _.isUndefined(document[prop]) then continue
    meta = schema[prop]
    if _.isArray(meta) 
      if not meta[0].type
        for item in document[prop] or []
          document[prop]._id ?= String(ObjectID())
          addObjectIdsToSubDocuments(item, meta[0])
    else if not meta.type
      document[prop]._id ?= String(ObjectID())
      addObjectIdsToSubDocuments(document[prop], meta)
    
