
exports.ns = ns = {}

ns.plugin = (schema, options) ->
  options ?= {}
  
  schema.add({lft: {type: Number}}) 
  schema.add({rgt: {type: Number}}) 
  schema.add({parentId: {type: String}}) 

  schema.index({parentId: 1}) 
  schema.index({lft: 1}) 
  schema.index({rgt: 1}) 


ns.setRoot = (_type, root, callback) ->
  root.parentId = null
  root.lft = 1
  root.rgt = 2
  save(_type, root, callback)


ns.addNode = (_type, node, parentId, callback) ->
  findById _type, parentId, (err, parent) -> # find parent
    if err then return callback(err)
    node.parentId = parentId # update node
    node.lft = parent.rgt
    node.rgt = node.lft + 1
    async.parallel [
      (done) -> # save node
        save(_type, node, done)
      (done) -> # update lefts
        where = {lft: {$gt: node.lft}}
        values = {$inc: {lft: 2, rgt: 2}}
        update(_type, where, values, done)
      (done) -> # update rights
        where = {lft: {$lt: node.lft}, rgt: {$gte: node.lft}}
        values = {$inc: {rgt: 2}}
        update(_type, where, values, done)
    ], (err, results) ->
      callback(err, results[0])


ns.removeNode = (_type, nodeId, callback) ->
  findById _type, nodeId, (err, node) ->
    if err then return callback(err)
    if not node.lft or not node.rgt
      return callback(new Error('Can not remove a node not in the nested set.'))
    if node.lft + 1 isnt node.rgt # dont allow removal of a node in the middle of the tree
      return callback(new Error('Can not remove a node that has children.'))
    async.parallel [
      (done) -> # update all peer nodes to right
        where = {lft: {$gt: node.lft}}
        values = {$inc: {lft: -2, rgt: -2}}
        update(_type, where, values, done)
      (done) -> # update all parent nodes
        where = {lft: {$lt: node.lft}, rgt: {$gt: node.lft}}
        values = {$inc: {rgt: -2}}
        update(_type, where, values, done)
      (done) -> # clear and save node
        node.lft = undefined
        node.rgt = undefined 
        node.parentId = undefined
        save(_type, node, done)
    ], (err) ->
      callback(err)


ns.findAncestors = (_type, nodeId, callback) ->
  findById _type, nodeId, (err, node) ->
    if err then return callback(err)
    query = {where: {lft: {$lt: node.lft}, rgt: {$gt: node.rgt}}}
    find(_type, query, callback)


ns.findDescendants = (_type, nodeId, callback) ->
  findById _type, nodeId, (err, node) ->
    if err then return callback(err)
    query = {where: {lft: {$gt: node.lft}, rgt: {$lt: node.rgt}}}
    find(_type, query, callback)


ns.findChildren = (_type, nodeId, callback) ->
  query = {where: {parentId: nodeId}}
  find(_type, query, callback)
    