//@ sourceMappingURL=stringizeObjectID.map
// Generated by CoffeeScript 1.6.1
(function() {
  var ObjectID, convertDocOID2String, isObjectID, isSubDoc, mongodb, _,
    __hasProp = {}.hasOwnProperty;

  mongodb = require('mongodb');

  ObjectID = mongodb.ObjectID;

  _ = require('underscore');

  exports.beforeSave = function(document, schema, callback) {
    var convert;
    convert = function(doc, fields) {
      var id, meta, property, val, value, _results;
      _results = [];
      for (property in doc) {
        if (!__hasProp.call(doc, property)) continue;
        value = doc[property];
        meta = fields[property];
        if (_.isUndefined(meta) && property !== '_id') {
          continue;
        }
        if (_.isArray(meta)) {
          meta = meta[0];
        }
        if (property === '_id' || meta.type === ObjectID) {
          if (_.isArray(value)) {
            _results.push(document[property] = (function() {
              var _i, _len, _results1;
              _results1 = [];
              for (_i = 0, _len = value.length; _i < _len; _i++) {
                id = value[_i];
                if (_.isString(id)) {
                  _results1.push(new ObjectID(id));
                }
              }
              return _results1;
            })());
          } else {
            if (_.isString(value)) {
              _results.push(document[property] = new ObjectID(value));
            } else {
              _results.push(void 0);
            }
          }
        } else if (meta.type === 'SubDoc') {
          if (_.isArray(value)) {
            _results.push((function() {
              var _i, _len, _results1;
              _results1 = [];
              for (_i = 0, _len = value.length; _i < _len; _i++) {
                val = value[_i];
                _results1.push(convert(val, meta));
              }
              return _results1;
            })());
          } else {
            _results.push(convert(value, meta));
          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };
    convert(document, schema.fields);
    return callback();
  };

  exports.afterSave = function(document, schema, callback) {
    convertDocOID2String(document);
    return callback();
  };

  exports.beforeFind = function(query, schema, callback) {
    var condition, id, meta, property, _ref;
    _ref = query.where;
    for (property in _ref) {
      if (!__hasProp.call(_ref, property)) continue;
      condition = _ref[property];
      meta = schema.fields[property];
      if (_.isArray(meta)) {
        meta = meta[0];
      }
      if (property === '_id' || meta.type === ObjectID) {
        if (condition != null ? condition.$in : void 0) {
          condition.$in = (function() {
            var _i, _len, _ref1, _results;
            _ref1 = condition.$in;
            _results = [];
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              id = _ref1[_i];
              if (_.isString(id)) {
                _results.push(new ObjectID(id));
              }
            }
            return _results;
          })();
        } else {
          if (_.isString(condition)) {
            query.where[property] = new ObjectID(condition);
          }
        }
      }
    }
    return callback();
  };

  exports.afterFind = function(query, schema, documents, callback) {
    var doc, _i, _len;
    for (_i = 0, _len = documents.length; _i < _len; _i++) {
      doc = documents[_i];
      convertDocOID2String(doc);
    }
    return callback();
  };

  isObjectID = function(val) {
    if ((val != null ? val._bsontype : void 0) === 'ObjectID') {
      return true;
    } else {
      return false;
    }
  };

  isSubDoc = function(val) {
    if (_.isString(val) || _.isDate(val) || _.isNumber(val) || _.isUndefined(val) || _.isNull(val) || _.isArray(val) || _.isBoolean(val) || isObjectID(val)) {
      return false;
    } else if (_.isObject(val)) {
      return true;
    } else {
      return false;
    }
  };

  convertDocOID2String = function(doc) {
    var i, item, prop, val, _results;
    _results = [];
    for (prop in doc) {
      if (!__hasProp.call(doc, prop)) continue;
      val = doc[prop];
      if (_.isArray(val)) {
        _results.push((function() {
          var _i, _len, _results1;
          _results1 = [];
          for (i = _i = 0, _len = val.length; _i < _len; i = ++_i) {
            item = val[i];
            if (isObjectID(item)) {
              _results1.push(doc[prop][i] = String(item));
            } else if (isSubDoc(item)) {
              _results1.push(convertDocOID2String(item));
            } else {
              _results1.push(void 0);
            }
          }
          return _results1;
        })());
      } else if (isObjectID(val)) {
        _results.push(doc[prop] = String(val));
      } else if (isSubDoc(val)) {
        _results.push(convertDocOID2String(val));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

}).call(this);