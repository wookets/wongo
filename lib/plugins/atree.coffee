#
# An implementation of the ancestor array tree pattern for mongodb
# http://docs.mongodb.org/manual/tutorial/model-tree-structures-with-ancestors-array/
#
_ = require 'underscore'

wongo = require __dirname + '/../wongo'

module.exports = (schema, options) ->
  options ?= {}
  # add a field to the schema
  schema.fields.ancestors = [{type: String, required: true}]
  schema.fields.parent = {type: String}
  # add an index for faster queries
  schema.indexes.push({ancestors: 1})
  schema.indexes.push({parent: 1})

  # before save, make sure path and parent match, else throw an exception to the developer
  schema.middleware.beforeValidate.push (document, schema, callback) ->
    document.ancestors ?= []
    for ancestor in document.ancestors
      if _.isNull(ancestor) then return callback('Can not have a null ancestor.')
    document.parent = _.last(document.ancestors) # use the ancestors as a book of record to set the parent
    callback()

  # after remove, also cleanup any orphaned paths
  schema.middleware.afterRemove.push (document, schema, callback) ->
    # remove all descendants (otherwise they will be orphaned)
    query = {ancestors: document._id}
    wongo.find schema._type, query, (err, result) ->
      if err then return callback(err)
      if _.isEmpty(result) then return callback(err)
      wongo.remove schema._type, result, (err) ->
        callback(err)