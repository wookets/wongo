// Generated by CoffeeScript 1.4.0
(function() {
  var Schema, async, find, findOne, mongoose, _,
    __hasProp = {}.hasOwnProperty;

  mongoose = require('mongoose');

  async = require('async');

  _ = require('underscore');

  /*
  # Easy access mongoose pass thru
  */


  exports.Schema = Schema = mongoose.Schema;

  /*
  # Query operations
  */


  exports.find = find = function(_type, query, callback) {
    var Type, mq;
    if (!_type || !_.isString(_type)) {
      return callback('InvalidParameter', 'The parameter _type is required.');
    }
    if (!query) {
      return callback('InvalidParamter', 'The parameter query is required.');
    }
    Type = mongoose.model(_type);
    mq = Type.find(query.where, query.select, {
      sort: query.sort,
      limit: query.limit,
      skip: query.limit
    });
    mq.lean();
    return mq.exec(function(err, docs) {
      return callback(err, docs);
    });
  };

  exports.findOne = findOne = function(_type, query, callback) {
    if (query == null) {
      query = {};
    }
    query.limit = 1;
    return find(_type, query, function(err, result) {
      if (!err && result) {
        result = result[0];
      }
      return callback(err, result);
    });
  };

  exports.findById = function(_type, _id, callback) {
    return findOne(_type, {
      where: {
        _id: _id
      }
    }, callback);
  };

  /*
  # CRUD operations
  */


  exports.save = function(resource, callback) {
    var Type, key, newArray, val1, value, _i, _len, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
    if (!resource) {
      return callback('InvalidParameter', 'The resource must be a valid object.');
    }
    if (!resource._type || !_.isString(resource._type)) {
      return callback('InvalidParameter', 'The resource must have a valid _type before it can be saved.');
    }
    Type = mongoose.model(resource._type);
    for (key in resource) {
      if (!__hasProp.call(resource, key)) continue;
      value = resource[key];
      if ((_ref = Type.schema.path(key)) != null ? (_ref1 = _ref.options) != null ? _ref1.ref : void 0 : void 0) {
        resource[key] = _.isObject(value) ? value._id : value;
      } else if ((_ref2 = Type.schema.path(key)) != null ? (_ref3 = _ref2.options) != null ? (_ref4 = _ref3.type) != null ? (_ref5 = _ref4[0]) != null ? _ref5.ref : void 0 : void 0 : void 0 : void 0) {
        newArray = [];
        for (_i = 0, _len = value.length; _i < _len; _i++) {
          val1 = value[_i];
          if (_.isObject(val1)) {
            newArray.push(val1._id);
          } else {
            newArray.push(val1);
          }
        }
        resource[key] = newArray;
      }
    }
    if (resource._id) {
      return Type.findById(resource._id, function(err, doc) {
        var key2;
        if (err) {
          return callback('ResourceNotSaved', err.message);
        }
        for (key2 in resource) {
          if (!__hasProp.call(resource, key2)) continue;
          value = resource[key2];
          if (key2 === '_id') {
            continue;
          }
          doc[key2] = value;
        }
        return doc.save(function(err) {
          if (callback) {
            return callback(err, doc != null ? doc.toObject({
              getters: true
            }) : void 0);
          }
        });
      });
    } else {
      return Type.create(resource, function(err, doc) {
        if (callback) {
          return callback(err, doc != null ? doc.toObject({
            getters: true
          }) : void 0);
        }
      });
    }
  };

  exports.update = function(_type, where, values, callback) {
    var Type;
    Type = mongoose.model(_type);
    return Type.update(where, values, {
      multi: true
    }, callback);
  };

}).call(this);