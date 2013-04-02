
_ = require 'underscore'

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
          prune(item, meta[0]) if _.isObject(item)
      else if _.isObject(val)           # handle embedded document
        prune(val, meta)
  prune(document, schema.fields)
  callback()