
_ = require 'underscore'
mongodb = require 'mongodb'
ObjectID = mongodb.ObjectID

options = require __dirname + '/../options'

#
# Allow a user to run a validation on a document (or partial document)
#
module.exports = (document, schema, callback) ->
  # validate every field
  if document._id # only validate properties that exist
    for own prop, val of document
      continue if prop is '_id'
      result = validateField(document, prop, schema.fields[prop])
      if _.isString(result) then return callback(new Error(result))
  else # validate all properties on schema
    for own field, meta of schema.fields
      if prop is '_id' then continue
      result = validateField(document, field, meta)
      if _.isString(result) then return callback(new Error(result))
  callback()

validateField = (document, field, meta) ->
  value = document[field]
  if meta.required and _.isUndefined(value) then return field + ' is required.'
  if _.isArray(meta)
    if meta[0].required and _.isUndefined(value) then return field + ' is required.'
    validateField(field, item, meta[0]) for item in value or []
  else
    switch meta.type
      when String
        if value and not _.isString(value) then return field + ' needs to be a string.'
        if meta.min and value?.length < meta.min then return field + ' needs to be at least ' + meta.min + ' characters in length.'
        if meta.max and value?.length > meta.max then return field + ' needs to be at most ' + meta.max + ' characters in length.'
        if meta.enum and not _.contains(meta.enum, value) then return field + ' must be valid.'
      when Number
        if value and not _.isNumber(value) then return field + ' needs to be a number.'
        if meta.min and value < meta.min then return field + ' needs to be greater than ' + meta.min + '.'
        if meta.max and value > meta.max then return field + ' needs to be less than or equal to ' + meta.max + '.'
      when Boolean
        if value and not _.isBoolean(value) then return field + ' needs to be a boolean.'
      when Date
        if value and not _.isDate(value) then return field + ' needs to be a date.'
      when ObjectID
        if options.stringizeObjectID then return # this will get ObjectID'd later...
        if value and not _.isObject(value) then return field + ' needs to be an ObjectID.'