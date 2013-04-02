
_ = require 'underscore'

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
  
  # normalize schema 
  normalize(schema.fields)

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
  for own field, meta of schema
    if _.isArray(meta) 
      switch meta[0] 
        when String, Number, Boolean, Date then schema[field][0] = {type: meta[0]}
      if not schema[field][0].type then normalize(meta[0])
    else if not meta.type
      switch meta
        when String, Number, Boolean, Date then schema[field] = {type: meta}
        else normalize(meta)

#
# This will apply any options set on the schema
#
applyOptions = (schema) ->
  schema.options ?= {}
  schema.options.convertIdsToStrings ?= options.convertIdsToStrings or true

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
  schema.middleware = {beforeSave: [], afterSave: [], beforeFind: [], afterFind: [], beforeRemove: [], afterRemove: []}
  # prune
  prune = schema.hooks?.prune # check schema defined
  prune = options.prune if _.isUndefined(prune) # check option defined
  prune = hooks.prune if prune is true # if for whatever reason the user set prune to true, use internal 
  if _.isFunction(prune)
    schema.middleware.beforeSave.push(prune)
  # apply defaults
  applyDefaults = schema.hooks?.applyDefaults
  applyDefaults = options.applyDefaults if _.isUndefined(applyDefaults)
  applyDefaults = hooks.applyDefaults if applyDefaults is true 
  if _.isFunction(applyDefaults)
    schema.middleware.beforeSave.push(applyDefaults)
  # validate
  validate = schema.hooks?.validate
  validate = options.validate if _.isUndefined(validate)
  validate = hooks.validate if validate is true
  if _.isFunction(validate)
    schema.middleware.beforeSave.push(validate)
  # generate subdoc id
  generateSubdocIds = schema.hooks?.generateSubdocIds
  generateSubdocIds = options.generateSubdocIds if _.isUndefined(generateSubdocIds)
  generateSubdocIds = hooks.generateSubdocIds if generateSubdocIds is true
  if _.isFunction(generateSubdocIds)
    schema.middleware.beforeSave.push(generateSubdocIds)
  # before save
  beforeSave = schema.hooks?.beforeSave
  beforeSave = options.beforeSave if _.isUndefined(beforeSave)
  if _.isFunction(beforeSave)
    schema.middleware.beforeSave.push(beforeSave)
  # after save
  afterSave = schema.hooks?.afterSave
  afterSave = options.afterSave if _.isUndefined(afterSave)
  if _.isFunction(afterSave) 
    schema.middleware.afterSave.push(afterSave)
    
  # before find
  beforeFind = schema.hooks?.beforeFind
  beforeFind = options.beforeFind if _.isUndefined(beforeFind)
  if _.isFunction(beforeFind) 
    schema.middleware.beforeFind.push(beforeFind)
  # populate
  populate = schema.hooks?.populate
  populate = options.populate if _.isUndefined(populate)
  populate = hooks.populate if populate is true
  if _.isFunction(populate)
    schema.middleware.afterFind.push(populate)
  # after find
  afterFind = schema.hooks?.afterFind
  afterFind = options.afterFind if _.isUndefined(afterFind)
  if _.isFunction(afterFind) 
    schema.middleware.afterFind.push(afterFind)
  
  # load document before remove
#   loadDocumentBeforeRemove
#     (next) -> # if documentOrId is a String then assume _id and load document
#       if document then return next()
#       exports.findById _type, _id, (err, result) ->
#         document = result
#         next(err)
  # before remove
  beforeRemove = schema.hooks?.beforeRemove
  beforeRemove = options.beforeRemove if _.isUndefined(beforeRemove)
  if _.isFunction(beforeRemove) 
    schema.middleware.beforeRemove.push(beforeRemove)
  # after remove
  afterRemove = schema.hooks?.afterRemove
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
    else # [function]
      plugin(schema)


#
# ensure our indexes as defined on the schema are created
#
ensureIndexes = (_type, schema) ->
  for index in schema.indexes ? []
    mongo.ifConnected () ->
      if _.isArray(index) 
        mongo.db.ensureIndex(_type, index[0], index[1], (err) -> if err then throw err)
      else 
        mongo.db.ensureIndex(_type, index, (err) -> if err then throw err)


    
