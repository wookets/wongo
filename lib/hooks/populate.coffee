
_ = require 'underscore'
async = require 'async'

crud = require __dirname + '/../crud'

#
# Allows users to specify a populate option in a query object 
#
module.exports = (query, schema, documents, callback) ->
  if _.isUndefined(query.populate) or _.isEmpty(query.populate)
    return callback()

  popArray = [] # we normalize everything into an array for easy processing later

  # support string with spaces (same as mongoose 3.6)
  if _.isString(query.populate)
    for path in query.populate.split(' ')
      popArray.push({path: path}) # marshel string into the 'purer' object syntax
  # support array populate since its easy
  else if _.isArray(query.populate)
    for path in query.populate
      popArray.push({path: path})
  # support object mapping (with query options), imho cleaner than mongoose
  else
    for own path, popQuery of query.populate
      popArray.push({path: path, query: popQuery})

  # loop thru each populate, async to speed things along
  async.each popArray, (pop, nextInLoop) -> # loop thru populates defined and do each one async (to speed things along)
    # find ref on schema (in the future we should make this recursive and support chained paths)
    for prop, val of schema.fields
      if _.isArray(val) # support array schema fields
        if prop is pop.path or val[0].populateAlias is pop.path # support populateAlias if defined on the schema
          pop_type = val[0].ref
          pop_prop = prop
      else
        if prop is pop.path or val.populateAlias is pop.path
          pop_type = val.ref
          pop_prop = prop
    # if we never found the pop_type, we need to throw an error because it doesnt exist on the schema
    if _.isUndefined(pop_type) or _.isUndefined(pop_prop) or _.isEmpty(pop_type)
      return callback(new Error('Populate property ' + pop.path + ' could not be found on schema.'))
    # we need to pull out the _ids from the property of each doc in the original query
    _ids = []
    for doc in documents
      if _.isArray(doc[pop_prop])
        _ids = _.union(doc[pop_prop], _ids)
      else 
        _ids.push(doc[pop_prop])
    _ids = _.uniq(_ids) # we dont need any duplicates
    # we need to query for each pop type based on assembled _ids
    popQuery = pop.query or {}
    if not popQuery.where then popQuery = {where: popQuery} # if 'where' isnt present, automatically nest
    popQuery.where._id = {$in: _ids}
    crud.find pop_type, popQuery, (err, pop_docs) ->
      if err then return nextInLoop(err)
      # assign pop_docs to the original documents
      for doc in documents
        for pop_doc in pop_docs
          if _.isArray(doc[pop_prop])
            for item, i in doc[pop_prop]
              if pop_doc._id is item
                doc[pop.path] ?= []
                doc[pop.path][i] = pop_doc
          else
            if String(pop_doc._id) is String(doc[pop_prop])
              doc[pop.path] = pop_doc
      nextInLoop()
  , callback

#
#findPopReference = (pop, schema) ->
#  for prop, val in schema or {}
#    if _.isArray(val)
#      if val[0].populateAlias is pop then return val[0].ref
#    else
#      if val.populateAlias is pop then return val.ref
#
      #
# Adds populate support for find queries.
# This is different from mongoose, because it allows you to define a populateAlias
# examples:
# authorIds: [{type: String, ref: 'Author', populateAlias: 'authors'}] // create a new property 'authors'
# authors: [{type: ObjectID, ref: 'Author', populateAlias: 'authors'}] // overwrite property (like mongoose)
# author: {type: String, ref: 'Author', populateAlias: 'authorObj'} // create a new property 'authorObj'
#



