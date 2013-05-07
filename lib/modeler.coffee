
_ = require 'underscore'
async = require 'async'

hooks = require __dirname + '/hooks'
mongo = require __dirname + '/mongo'
options = require __dirname + '/options'

#
# Schema
#
exports.schemas = schemas = {}
exports.schema = (_type, schema) ->
  if not _type or not _.isString(_type) then throw new Error('_type required.')
  
  if not schema 
    if not schemas[_type] then throw new Error('_type [' + _type + '] not recognized')
    return schemas[_type]
  
  if not schema.fields or _.isEmpty(schema.fields) then throw new Error('We need to have some sort of schema or whats the point?')

  # define collectionName if not defined
  schema._type = _type
  schema.collectionName ?= _type

  # normalize schema
  normalize(schema)

  # apply options
  applyOptions(schema)
  
  # generate paths
  #generatePaths(schema)

  # read in hooks and add to middleware
  setupMiddleware(schema)
  
  # plugin support
  applyPlugins(schema)
  
  # ensure indexes
  ensureIndexes(_type, schema)
  
  # register schema
  schemas[_type] = schema

  return schema


#
# This will convert schema property types; e.g. String becomes {type: String}
# This will recurse the documents and do all subdocuments and arrays
#
normalize = (schema) ->
  schema.indexes ?= []
  schema.plugins ?= []
  schema.hooks ?= {}
  schema.options ?= {}

  # normalize fields
  for own field, meta of schema.fields
    if not meta then throw new Error('We were expecting ' + field + ' to have proper meta.')
    if _.isArray(meta) # support array properties
      if not meta[0] then throw new Error('We were expecting ' + field + ' to have proper array meta.')
      if meta[0].type then continue # ignore types already defined
      switch meta[0]
        when String, Number, Boolean, Date
          meta[0] = {type: meta[0]} # nest via type
        else # they didnt define a standard type, assume this is a subdoc
          normalize(meta[0]) # recurse and check subdoc for any noramlization
          meta[0].type = 'SubDoc'
    else
      if meta.type then continue # ignore types already defined
      switch meta
        when String, Number, Boolean, Date
          schema.fields[field] = {type: meta}
        else
          normalize(meta)
          meta.type = 'SubDoc'

#
# This will apply any options set on the schema
#
applyOptions = (schema) ->
  schema.options ?= {}

#
# generate paths like mongoose does if someone would want to go that route
#
# generatePaths = (schema) ->
#   schema.paths = {}
#   for own prop, val of schema.fields

#
# Add hooks, defaults first (or overrides), then user defined hooks
#
setupMiddleware = (schema) ->
  schema.middleware =
    beforeValidate: [] # prune, defaults, user defined
    beforeSave: [] # validate, user defined
    rightBeforeSave: [] # generate subdoc id, String to OID
    afterSave: [] # convert OID back to String, user defined
    beforeFind: []
    afterFind: []
    beforeRemove: []
    afterRemove: []

  #
  # Save
  #

  # prune
  prune = schema.hooks.prune # check schema defined
  prune = options.prune if _.isUndefined(prune) # check option defined
  prune = hooks.prune if prune is true # if for whatever reason the user set prune to true, use internal 
  if _.isFunction(prune)
    schema.middleware.beforeValidate.push(prune)

  # apply defaults
  applyDefaults = schema.hooks.applyDefaults
  applyDefaults = options.applyDefaults if _.isUndefined(applyDefaults)
  applyDefaults = hooks.applyDefaults if applyDefaults is true 
  if _.isFunction(applyDefaults)
    schema.middleware.beforeValidate.push(applyDefaults)

  # validate
  validate = schema.hooks.validate
  validate = options.validate if _.isUndefined(validate)
  validate = hooks.validate if validate is true
  if _.isFunction(validate)
    schema.middleware.beforeSave.push(validate)

  # user defined before save
  beforeSave = schema.hooks.beforeSave
  beforeSave = options.beforeSave if _.isUndefined(beforeSave)
  if _.isFunction(beforeSave)
    schema.middleware.beforeSave.push(beforeSave)

  # generate subdoc id
  generateSubdocIds = schema.hooks.generateSubdocIds
  generateSubdocIds = options.generateSubdocIds if _.isUndefined(generateSubdocIds)
  generateSubdocIds = hooks.generateSubdocIds if generateSubdocIds is true
  if _.isFunction(generateSubdocIds)
    schema.middleware.rightBeforeSave.push(generateSubdocIds)

  # convert strings into objectIds if necessary
  stringizeObjectIDBeforeSave = schema.hooks.stringizeObjectIDBeforeSave
  stringizeObjectIDBeforeSave = options.stringizeObjectID if _.isUndefined(stringizeObjectIDBeforeSave)
  stringizeObjectIDBeforeSave = hooks.stringizeObjectIDBeforeSave if stringizeObjectIDBeforeSave is true
  if _.isFunction(stringizeObjectIDBeforeSave)
    schema.middleware.rightBeforeSave.push(stringizeObjectIDBeforeSave)

  # execute save

  # convert objectIds to strings for easier usage later
  stringizeObjectIDAfterSave = schema.hooks.stringizeObjectIDAfterSave
  stringizeObjectIDAfterSave = options.stringizeObjectID if _.isUndefined(stringizeObjectIDAfterSave)
  stringizeObjectIDAfterSave = hooks.stringizeObjectIDAfterSave if stringizeObjectIDAfterSave is true
  if _.isFunction(stringizeObjectIDAfterSave)
    schema.middleware.afterSave.push(stringizeObjectIDAfterSave)

  # user defined after save
  afterSave = schema.hooks.afterSave
  afterSave = options.afterSave if _.isUndefined(afterSave)
  if _.isFunction(afterSave) 
    schema.middleware.afterSave.push(afterSave)


  #
  # Find
  #

  # user defined before find
  beforeFind = schema.hooks.beforeFind
  beforeFind = options.beforeFind if _.isUndefined(beforeFind)
  if _.isFunction(beforeFind) 
    schema.middleware.beforeFind.push(beforeFind)

  # stringize ObjectID before querying
  stringizeObjectIDBeforeFind = schema.hooks.stringizeObjectIDBeforeFind
  stringizeObjectIDBeforeFind = options.stringizeObjectID if _.isUndefined(stringizeObjectIDBeforeFind)
  stringizeObjectIDBeforeFind = hooks.stringizeObjectIDBeforeFind if stringizeObjectIDBeforeFind is true
  if _.isFunction(stringizeObjectIDBeforeFind)
    schema.middleware.beforeFind.push(stringizeObjectIDBeforeFind)

  # execute find

  # convert ObjectIDs to Strings so we can retain our sanity
  stringizeObjectIDAfterFind = schema.hooks.stringizeObjectIDAfterFind
  stringizeObjectIDAfterFind = options.stringizeObjectID if _.isUndefined(stringizeObjectIDAfterFind)
  stringizeObjectIDAfterFind = hooks.stringizeObjectIDAfterFind if stringizeObjectIDAfterFind is true
  if _.isFunction(stringizeObjectIDAfterFind)
    schema.middleware.afterFind.push(stringizeObjectIDAfterFind)

  # populate
  populate = schema.hooks.populate
  populate = options.populate if _.isUndefined(populate)
  populate = hooks.populate if populate is true
  if _.isFunction(populate)
    schema.middleware.afterFind.push(populate)

  # user defined after find
  afterFind = schema.hooks.afterFind
  afterFind = options.afterFind if _.isUndefined(afterFind)
  if _.isFunction(afterFind) 
    schema.middleware.afterFind.push(afterFind)


  #
  # Remove
  #
  # load document before remove
#   loadDocumentBeforeRemove
#     (next) -> # if documentOrId is a String then assume _id and load document
#       if document then return next()
#       exports.findById _type, _id, (err, result) ->
#         document = result
#         next(err)
  # before remove
  beforeRemove = schema.hooks.beforeRemove
  beforeRemove = options.beforeRemove if _.isUndefined(beforeRemove)
  if _.isFunction(beforeRemove)
    schema.middleware.beforeRemove.push(beforeRemove)
  # after remove
  afterRemove = schema.hooks.afterRemove
  afterRemove = options.afterRemove if _.isUndefined(afterRemove)
  if _.isFunction(afterRemove) 
    schema.middleware.afterRemove.push(afterRemove)


#
# This method will call any passed in plugins, which are just functions that receive the schema and any options
#
applyPlugins = (schema) ->
  for plugin in schema.plugins ? []
    if _.isArray(plugin) # [function, args]
      plugin[0](schema, plugin[1])
    else if _.isFunction(plugin) # [function]
      plugin(schema)
    else
      throw new Error('The plugin defined for ' + schema._type + ' is incorrectly defined (must be an array or a function).')

#
# ensure our indexes as defined on the schema are created
#
ensureIndexes = (_type, schema) ->
  async.forEach schema.indexes, (index, nextInLoop) ->
    mongo.ifConnected () ->
      if _.isArray(index)
        mongo.db.ensureIndex(schema.collectionName, index[0], index[1], (err) -> if err then throw err)
      else 
        mongo.db.ensureIndex(schema.collectionName, index, (err) -> if err then throw err)
      nextInLoop()
    
