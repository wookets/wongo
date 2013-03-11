# require './config'
# wongo = require '../lib/wongo'
# 
# wongo.connect(process.env.DB_URL)
# 
# plugin_example = (schema, options) ->
#   property = {}
#   property[options?.property or 'plugin1'] = {type: String}
#   schema.add(property)
#   
# 
# # add in Mock models that we can use to test against  
# wongo.schema 'Mock', 
#   fields: 
#     # simplest example
#     name: {type: String, default: 'Mock Me', required: true}
#     
#     # different types
#     number: Number
#     date: Date
#     boolean: Boolean
#     array: [String]
#     #object_id: {type: 'ObjectId'}
#     #mixed: {type: 'Mixed'}
#     
#     # embedded documents
#     embedded_doc: 
#       name: {type: String}
#     embedded_array: [
#       name: {type: String}
#     ]
#     
#     # reference examples
#     reference: {type: String, ref: 'Mock'}
#     array_of_references: [{type: String, ref: 'Mock'}]
#     parent: {type: String, ref: 'Mock'}
#     children: [{type: String, ref: 'Mock'}]
#     
#     # embedded references
#     embedded_array2: [
#       name: String
#       ref: {type: String, ref: 'Mock'}
#       ref_array: [{type: String, ref: 'Mock'}] 
#     ]
#     
#     # hooks - make sure before and after save fields are being modified
#     beforeSave: {type: String, default: 'not_changed'}
#     afterSave: {type: String, default: 'not_changed'}
# 
#   plugins: [
#     plugin_example
#     [plugin_example, {property: 'plugin2'}]
#   ]
#   
#   indexes: [
#     {name: 1}
#   ]
#   
#   options: 
#     id: false
#     _type: true
# 
#   hooks:
#     beforeSave: (document, next) ->
#       document.beforeSave = 'changed'
#       next()
#     
#     afterSave: (document, next) ->
#       document.afterSave = 'changed'
#       next()
# 
#     beforeRemove: (_id, next) ->
#       next()
#     
#     afterRemove: (_id, next) ->
#       next()
# 
# 
# # add in Mock models that we can use to test against  
# wongo.schema 'MockHierarchy', 
#   fields: 
#     name: String
#   
#   plugins: [
#     wongo.ns.plugin
#   ]
