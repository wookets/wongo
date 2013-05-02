//@ sourceMappingURL=find.test.map
// Generated by CoffeeScript 1.6.1
(function() {
  var assert, wongo;

  assert = require('assert');

  wongo = require('../lib/wongo');

  wongo.schema('MockFind', {
    fields: {
      name: String,
      selectField: String
    }
  });

  describe('Wongo Find', function() {
    var docs;
    docs = [
      {
        name: 'Meow'
      }, {
        name: 'Boo',
        selectField: 'Cow'
      }, {
        name: 'Fran'
      }, {
        name: 'Kitty'
      }, {
        name: 'Woof'
      }
    ];
    it('should be able to save all documents', function(done) {
      return wongo.save('MockFind', docs, function(err, result) {
        var item, _i, _len;
        assert.ifError(err);
        for (_i = 0, _len = result.length; _i < _len; _i++) {
          item = result[_i];
          assert.ok(item._id);
        }
        return done();
      });
    });
    it('should be able to find all documents', function(done) {
      var query;
      query = {};
      return wongo.find('MockFind', query, function(err, result) {
        assert.ifError(err);
        assert.equal(result != null ? result.length : void 0, 5);
        return done();
      });
    });
    it('should be able to find one document from many', function(done) {
      var query;
      query = {};
      return wongo.findOne('MockFind', query, function(err, result) {
        assert.ifError(err);
        assert.ok(result);
        return done();
      });
    });
    it('should be able to find one document by name', function(done) {
      var query;
      query = {
        name: 'Boo'
      };
      return wongo.findOne('MockFind', query, function(err, result) {
        assert.ifError(err);
        assert.equal(result.name, 'Boo');
        return done();
      });
    });
    it('should be able to find documents by name', function(done) {
      var query;
      query = {
        name: 'Fran'
      };
      return wongo.find('MockFind', query, function(err, result) {
        assert.ifError(err);
        assert.equal(result.length, 1);
        assert.equal(result[0].name, 'Fran');
        return done();
      });
    });
    it('should be able to find select fields on document', function(done) {
      var query;
      query = {
        select: 'name',
        where: {
          name: 'Boo'
        }
      };
      return wongo.findOne('MockFind', query, function(err, result) {
        assert.ifError(err);
        assert.equal(result.name, 'Boo');
        assert.ok(!result.selectField);
        return done();
      });
    });
    it('should be able to find documents by name with where', function(done) {
      var query;
      query = {
        where: {
          name: 'Fran'
        }
      };
      return wongo.find('MockFind', query, function(err, result) {
        assert.ifError(err);
        assert.equal(result.length, 1);
        assert.equal(result[0].name, 'Fran');
        return done();
      });
    });
    return it('should be able to limit documents to 3', function(done) {
      var query;
      query = {
        where: {},
        limit: 3
      };
      return wongo.find('MockFind', query, function(err, result) {
        assert.ifError(err);
        assert.equal(result.length, 3);
        return done();
      });
    });
  });

}).call(this);