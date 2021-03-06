//@ sourceMappingURL=mongo.map
// Generated by CoffeeScript 1.6.1
(function() {
  var MongoClient, mongodb, _;

  _ = require('underscore');

  mongodb = require('mongodb');

  MongoClient = mongodb.MongoClient;

  exports.db = null;

  exports.connect = function(url, options) {
    return MongoClient.connect(url, options, function(err, opened_db) {
      if (err) {
        throw err;
      }
      exports.db = opened_db;
    });
  };

  exports.ifConnected = function(callback) {
    var attempts, waitForDb;
    if (exports.db) {
      return callback();
    }
    attempts = 0;
    waitForDb = setInterval(function() {
      if (exports.db) {
        clearInterval(waitForDb);
        return callback();
      } else if (attempts === 20) {
        clearInterval(waitForDb);
        return callback(new Error('We waited and waited but the database is no where to be found. Did you use connect(url)?'));
      } else {
        return attempts += 1;
      }
    }, 250);
  };

  exports.collection = function(_type) {
    if (!_type || !_.isString(_type)) {
      throw new Error('_type required.');
    }
    return exports.db.collection(_type);
  };

}).call(this);
