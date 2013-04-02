
_ = require 'underscore'
mongodb = require 'mongodb'

ObjectID = mongodb.ObjectID

#
# add object _ids to sub-documents
#
module.exports = (document, schema, callback) ->
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
      