
_ = require 'underscore'

#
# Apply default values to fields if specified.
#
module.exports = (document, schema, callback) ->
  applyDefaults = (doc, fields) ->
    for own prop, meta of fields ? {}
      if _.isUndefined(meta) then continue # maybe the dev disabled prune!
      if _.isArray(meta) and meta[0]?.type # array of simple types (e.g. String)
        doc[prop] ?= meta[0].default
      else if _.isArray(meta) # check array of subdoc types
        for item in doc[prop] ? []
          applyDefaults(item, meta[0])
      else if not meta?.type # check object
        applyDefaults(doc[prop], meta)
      else
        if _.isUndefined(doc[prop]) and meta.default
          doc[prop] = meta.default
  applyDefaults(document, schema.fields)
  callback()
