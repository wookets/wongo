
_ = require 'underscore'
mongodb = require 'mongodb'
ObjectID = mongodb.ObjectID

#
# This method will prune (remove) all properties not explicitly defined on the schema.
#
module.exports = (document, schema, callback) ->
  prune = (document, fields) ->
    for own prop, val of document ? {}
      if prop is '_id' then continue
      meta = fields[prop]
      if not meta               # if property doesnt have a meta, remove it
        delete document[prop]
      else if _.isArray(meta)   # handle array embedded document
        for item in val ? []
          if meta[0].type is ObjectID # ignore ObjectID
            continue
          else if _.isObject(item)
            prune(item, meta[0])
      else if meta.type is ObjectID # ignore ObjectID
        continue
      else if _.isObject(val)           # handle embedded document
        prune(val, meta)
  prune(document, schema.fields)
  callback()
