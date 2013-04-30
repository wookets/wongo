
_ = require 'underscore'
async = require 'async'

crud = require __dirname + '/../crud'

#
# Allows users to specify a populate option in a query object 
#
module.exports = (query, schema, documents, callback) ->
  if not query.populate then return callback()
  runPopulateQueries(schema.fields, query.populate, documents, callback)

#
# Pop queries
#
runPopulateQueries = (fields, populate, docs, callback) ->
  if _.isString(populate) then populate = [populate] # string support
  #console.log 'pop'
  #console.log schema
  async.forEach populate, (pop, nextInLoop) -> # run some async queries to populate our model
    #console.log pop
    pop_type = null
    pop_prop = null
    for prop, val of fields or {}
      #console.log val
      if _.isArray(val) 
        if val[0].populateAlias is pop or pop is prop
          pop_type = val[0].ref
          pop_prop = prop
      else
        if val.populateAlias is pop or pop is prop
          pop_type = val.ref
          pop_prop = prop

    #console.log pop_type
    if not pop_type then throw new Error('Populate property ' + pop + ' could not be found on schema.')
    
    # we need to pull out the _id from each doc that was returned
    _ids = []
    for doc in docs
      if _.isArray(doc[pop_prop])
        _ids = _.union(doc[pop_prop], _ids)
      else 
        _ids.push(doc[pop_prop])
    
    # we need to query for each pop type based on assembled _ids
    crud.find pop_type, {where: {_id: {$in: _ids}}}, (err, pop_docs) ->
      if err then return nextInLoop(err)
      for doc in docs # assign back to doc 
        for pop_doc in pop_docs
          if _.isArray(doc[pop_prop])
            for item, i in doc[pop_prop]
              if pop_doc._id is item
                doc[pop] ?= []
                doc[pop][i] = pop_doc
          else
            if String(pop_doc._id) is String(doc[pop_prop])
              doc[pop] = pop_doc
      #console.log docs
      nextInLoop()  
  , (err) ->
    callback(err, docs)

findPopReference = (pop, schema) ->
  for prop, val in schema or {}
    if _.isArray(val) 
      if val[0].populateAlias is pop then return val[0].ref
    else
      if val.populateAlias is pop then return val.ref
      
      #
# Adds populate support for find queries.
# This is different from mongoose, because it allows you to define a populateAlias
# examples:
# authorIds: [{type: String, ref: 'Author', populateAlias: 'authors'}] // create a new property 'authors'
# authors: [{type: ObjectID, ref: 'Author', populateAlias: 'authors'}] // overwrite property (like mongoose)
# author: {type: String, ref: 'Author', populateAlias: 'authorObj'} // create a new property 'authorObj'
#


#
# Will normalize a populate string or array into an object
# e.g. 'author' becomes {author: {}}
# e.g. 'author post' becomes {author: {}, post: {}}
#
# exports.normalize = (populate) -> 
#   # if undefined
#   if _.isUndefined(populate) or _.isNull(populate) or _.isEmpty(populate) then return {}
#   # if string
#   if _.isString(populate)
#     pop = {}
#     if populate.indexOf(' ') isnt -1
#       pop[populate] = {}
#     else
#       for pop_i in populate.split(' ')
#         pop[pop_i] = {}
#     populate = pop
#   # if object, just return
#   return populate


