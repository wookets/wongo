
_ = require 'underscore'

#
# Apply default values to fields if specified.
#
module.exports = (document, schema, callback) ->
  applyDefaults = (document, fields) ->
    for own prop, val of document ? {}
      if prop is '_id' then continue
      meta = fields[prop]
      if _.isUndefined(meta) then continue # maybe the dev disabled prune!
      if _.isArray(meta) and meta[0]?.type # array of simple types (e.g. String)
        document[prop] ?= meta[0].default if _.isUndefined(val)
      else if _.isArray(meta) # check array of subdoc types
        applyDefaults(item, meta[0]) for item in val ? []
      else if not meta?.type # check object
        applyDefaults(val, meta)
      else
        document[prop] ?= meta.default if _.isUndefined(val)
  applyDefaults(document, schema.fields)
  callback()