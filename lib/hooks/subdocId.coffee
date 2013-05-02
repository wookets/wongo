
_ = require 'underscore'
mongodb = require 'mongodb'

ObjectID = mongodb.ObjectID

#
# add object _ids to sub-documents
#
module.exports = (document, schema, callback) ->
  generateSubdocIds = (document, fields) -> # recursive inline function 8P 
    for own prop, val of document
      if prop is '_id' then continue # ignore _id because we know it will never be a subdoc
      if _.isUndefined(val) or _.isEmpty(val) or _.isNull(val) then continue # ignore nulled properties
      meta = fields[prop]
      if _.isUndefined(meta) then continue # maybe the dev disabled prune!
      if _.isArray(meta) 
        if meta[0].type is 'SubDoc'
          for item in document[prop] or []
            document[prop]._id ?= ObjectID()
            generateSubdocIds(item, meta[0])
      else if meta.type is 'SubDoc'
        document[prop]._id ?= ObjectID()
        generateSubdocIds(document[prop], meta)
  generateSubdocIds(document, schema.fields)
  callback()
