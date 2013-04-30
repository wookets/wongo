
async = require 'async'

wongo = require __dirname + '/../wongo'

module.exports = (schema, options) ->
  options ?= {}

  schema.fields.lft = {type: Number}
  schema.fields.rgt = {type: Number}
  schema.fields.parentId = {type: String} 

  schema.indexes ?= []
  schema.indexes.push({parentId: 1})
  schema.indexes.push({lft: 1})
  schema.indexes.push({rgt: 1})
  
  ns = {}
  ns.setRoot = (_type, root, callback) ->
    root.parentId = null
    root.lft = 1
    root.rgt = 2
    wongo.save(_type, root, callback)

  ns.addNode = (_type, node, parentId, callback) ->
    wongo.findById _type, parentId, (err, parent) -> # find parent
      if err then return callback(err)
      node.parentId = parentId # update node
      node.lft = parent.rgt
      node.rgt = node.lft + 1
      async.parallel [
        (done) -> # save node
          wongo.save(_type, node, done)
        (done) -> # update lefts
          where = {lft: {$gt: node.lft}}
          values = {$inc: {lft: 2, rgt: 2}}
          collection = wongo.collection(_type)
          collection.update(where, values, {multi:true}, done)
        (done) -> # update rights
          where = {lft: {$lt: node.lft}, rgt: {$gte: node.lft}}
          values = {$inc: {rgt: 2}}
          collection = wongo.collection(_type)
          collection.update(where, values, {multi:true}, done)
      ], (err) ->
        callback(err, node)

  ns.removeNode = (_type, nodeId, callback) ->
    wongo.findById _type, nodeId, (err, node) ->
      if err then return callback(err)
      if not node.lft or not node.rgt
        return callback(new Error('Can not remove a node not in the nested set.'))
      if node.lft + 1 isnt node.rgt # dont allow removal of a node in the middle of the tree
        return callback(new Error('Can not remove a node that has children.'))
      async.parallel [
        (done) -> # update all peer nodes to right
          where = {lft: {$gt: node.lft}}
          values = {$inc: {lft: -2, rgt: -2}}
          collection = wongo.collection(_type)
          collection.update(where, values, {multi:true}, done)
        (done) -> # update all parent nodes
          where = {lft: {$lt: node.lft}, rgt: {$gt: node.lft}}
          values = {$inc: {rgt: -2}}
          collection = wongo.collection(_type)
          collection.update(where, values, {multi:true}, done)
        (done) -> # clear and save node
          node.lft = undefined
          node.rgt = undefined 
          node.parentId = undefined
          wongo.save(_type, node, done)
      ], (err) ->
        callback(err)
  
  ns.findAncestors = (_type, nodeId, callback) ->
    wongo.findById _type, nodeId, (err, node) ->
      if err then return callback(err)
      query = {where: {lft: {$lt: node.lft}, rgt: {$gt: node.rgt}}}
      wongo.find(_type, query, callback)
  
  ns.findDescendants = (_type, nodeId, callback) ->
    wongo.findById _type, nodeId, (err, node) ->
      if err then return callback(err)
      query = {where: {lft: {$gt: node.lft}, rgt: {$lt: node.rgt}}}
      wongo.find(_type, query, callback)
  
  ns.findChildren = (_type, nodeId, callback) ->
    query = {where: {parentId: nodeId}}
    wongo.find(_type, query, callback)
  wongo.ns = ns
  return
  