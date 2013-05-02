//@ sourceMappingURL=crud.test.map
// Generated by CoffeeScript 1.6.1
(function() {
  var assert, wongo;

  assert = require('assert');

  wongo = require('../lib/wongo');

  wongo.schema('Mock', {
    fields: {
      name: String,
      field2: String
    }
  });

  describe('Wongo CRUD', function() {
    var doc;
    doc = {
      name: 'Meow'
    };
    it('should be able to save a document', function(done) {
      return wongo.save('Mock', doc, function(err, result) {
        assert.ifError(err);
        assert.ok(result != null ? result._id : void 0);
        doc = result;
        return done();
      });
    });
    it('should be able to update a document', function(done) {
      doc.name = 'Moo';
      return wongo.save('Mock', doc, function(err, result) {
        assert.ifError(err);
        assert.ok(result);
        assert.equal(result._id, doc._id);
        assert.equal(result.name, 'Moo');
        return done();
      });
    });
    it('should be able to save a partial document', function(done) {
      var mini_doc;
      mini_doc = {
        _id: doc._id,
        field2: 'mantis'
      };
      return wongo.save('Mock', mini_doc, function(err, result) {
        assert.ifError(err);
        assert.ok(!result.name);
        assert.equal(result.field2, 'mantis');
        doc.field2 = result.field2;
        return done();
      });
    });
    it('should be able to unset a field by using null', function(done) {
      var mini_doc;
      mini_doc = {
        _id: doc._id,
        field2: null
      };
      return wongo.save('Mock', mini_doc, function(err, result) {
        assert.ifError(err);
        assert.ok(!result.name);
        assert.ok(!result.field2);
        return done();
      });
    });
    it('should be able to find a document', function(done) {
      var query;
      query = {
        name: 'Moo'
      };
      return wongo.find('Mock', query, function(err, result) {
        assert.ifError(err);
        assert.ok(result);
        assert.equal(result[0]._id, doc._id);
        return done();
      });
    });
    it('should be able to find one document', function(done) {
      var query;
      query = {
        name: 'Moo'
      };
      return wongo.findOne('Mock', query, function(err, result) {
        assert.ifError(err);
        assert.ok(result);
        assert.equal(result._id, doc._id);
        return done();
      });
    });
    it('should be able to find a document findById', function(done) {
      return wongo.findById('Mock', doc._id, function(err, result) {
        assert.ifError(err);
        assert.equal(result != null ? result._id : void 0, doc._id);
        return done();
      });
    });
    return it('should be able to remove a document', function(done) {
      return wongo.remove('Mock', doc, function(err) {
        assert.ifError(err);
        return done();
      });
    });
  });

}).call(this);