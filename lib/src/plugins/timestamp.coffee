#
# Addes a modifiedOn and createdOn timestamp to a schema and updates beforeSave.
#
module.exports = (schema, options) ->
  options ?= {}

  # add fields to schema
  schema.fields.createdOn = {type: Date, required: true}
  schema.fields.modifiedOn = {type: Date, required: true}
  
  # add beforeSave middleware
  schema.middleware.beforeSave.unshift (document, schema, callback) ->
    document.createdOn ?= new Date()
    document.modifiedOn = new Date()
    callback()
  
  return