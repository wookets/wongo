

#
# Mongo / Connection
#
mongo = require __dirname + '/mongo'
exports.connect = mongo.connect
exports.db = mongo.db
exports.ifConnected = mongo.ifConnected
exports.collection = mongo.collection


#
# Global options for schemas, hooks, and other stuff
#
options = require __dirname + '/options'
exports.options = options


#
# Schema / Modeling
#
modeler = require __dirname + '/modeler'
exports.schema = modeler.schema
exports.schemas = modeler.schemas



#
# Hooks / Middleware
#
hooks = require __dirname + '/hooks'
exports.validate = hooks.validate
exports.prune = hooks.prune


#
# Crud / Find / Query
#
crud = require __dirname + '/crud'
exports.save = crud.save
exports.remove = crud.remove
exports.removeAll = crud.removeAll
exports.clear = crud.clear
exports.find = crud.find
exports.findOne = crud.findOne
exports.findById = crud.findById
exports.findByIds = crud.findByIds
