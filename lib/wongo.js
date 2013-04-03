

//
// Mongo / Connection
//
var mongo = require(__dirname + '/build/mongo');
exports.connect = mongo.connect;
exports.db = mongo.db;
exports.ifConnected = mongo.ifConnected;
exports.collection = mongo.collection;


//
// Global options for schemas, hooks, and other stuff
//
var options = require(__dirname + '/build/options');
exports.options = options;


//
// Schema / Modeling
//
var modeler = require(__dirname + '/build/modeler');
exports.schema = modeler.schema;
exports.schemas = modeler.schemas;


//
// Hooks / Middleware
//
var hooks = require(__dirname + '/build/hooks');
exports.validate = hooks.validate;
exports.prune = hooks.prune;
exports.plugins = require(__dirname + '/build/plugins'); // expose internal plugins


//
// Crud / Find / Query
//
var crud = require(__dirname + '/build/crud');
exports.save = crud.save;
exports.remove = crud.remove;
exports.clear = crud.clear;
exports.find = crud.find;
exports.findOne = crud.findOne;
exports.findById = crud.findById;
exports.findByIds = crud.findByIds;
