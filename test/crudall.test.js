//@ sourceMappingURL=crudall.test.map
// Generated by CoffeeScript 1.6.1
(function() {
  var assert, wongo, _;

  _ = require('underscore');

  assert = require('assert');

  wongo = require('../lib/wongo');

  wongo.schema('MockAll', {
    fields: {
      name: String
    }
  });

  describe('Wongo CRUD All', function() {
    var docs;
    docs = [
      {
        name: 'Meow'
      }, {
        name: 'Boo'
      }, {
        name: 'Fran'
      }
    ];
    it('should be able to save all documents', function(done) {
      return wongo.save('MockAll', docs, function(err, result) {
        var item, _i, _len;
        assert.ifError(err);
        for (_i = 0, _len = result.length; _i < _len; _i++) {
          item = result[_i];
          assert.ok(item._id);
        }
        return done();
      });
    });
    it('should be able to remove all documents', function(done) {
      return wongo.remove('MockAll', docs, function(err, result) {
        assert.ifError(err);
        return done();
      });
    });
    it('should be verify all this worked with a find', function(done) {
      var query, _ids;
      _ids = _.pluck(docs, '_id');
      query = {
        _id: {
          $in: _ids
        }
      };
      return wongo.find('MockAll', query, function(err, result) {
        assert.ifError(err);
        assert.equal(result.length, 0);
        return done();
      });
    });
    it('should be able to save all documents', function(done) {
      return wongo.save('MockAll', docs, function(err, result) {
        var item, _i, _len;
        assert.ifError(err);
        for (_i = 0, _len = result.length; _i < _len; _i++) {
          item = result[_i];
          assert.ok(item._id);
        }
        return done();
      });
    });
    it('should be able to remove all documents by id', function(done) {
      var _ids;
      _ids = _.pluck(docs, '_id');
      return wongo.remove('MockAll', _ids, function(err, result) {
        assert.ifError(err);
        return done();
      });
    });
    return it('should be verify all this worked with a find', function(done) {
      var query, _ids;
      _ids = _.pluck(docs, '_id');
      query = {
        _id: {
          $in: _ids
        }
      };
      return wongo.find('MockAll', query, function(err, result) {
        assert.ifError(err);
        assert.equal(result.length, 0);
        return done();
      });
    });
  });

}).call(this);