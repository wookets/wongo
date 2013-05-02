//@ sourceMappingURL=plugins.test.map
// Generated by CoffeeScript 1.6.1
(function() {
  var assert, wongo, _;

  assert = require('assert');

  wongo = require('../lib/wongo');

  _ = require('underscore');

  wongo.schema('MockPlugin', {
    fields: {
      name: String
    },
    plugins: [wongo.plugins.timestamp]
  });

  wongo.schema('MockHierarchy', {
    fields: {
      name: String
    },
    plugins: [wongo.plugins.nestedset]
  });

  describe('Wongo Plugins', function() {
    var child1, child11, root;
    it('should save a MockPlugin and have Dates created for two properties', function(done) {
      var doc;
      doc = {
        name: 'woof'
      };
      return wongo.save('MockPlugin', doc, function(err, result) {
        assert.ifError(err);
        assert.ok(result._id);
        assert.ok(result.createdOn);
        assert.ok(_.isDate(result.modifiedOn));
        assert.ok(_.isDate(result.createdOn));
        return done();
      });
    });
    it('should have attached nested set methods to wongo namespace', function(done) {
      assert.ok(_.isFunction(wongo.ns.addNode));
      return done();
    });
    root = null;
    child1 = null;
    child11 = null;
    it('should set a root for the tree', function(done) {
      root = {
        name: 'Root'
      };
      return wongo.ns.setRoot('MockHierarchy', root, function(err, doc) {
        root = doc;
        assert.equal(doc.lft, 1);
        assert.equal(doc.rgt, 2);
        return done();
      });
    });
    it('should add a child to the root', function(done) {
      child1 = {
        name: 'child1'
      };
      return wongo.ns.addNode('MockHierarchy', child1, root._id, function(err, doc) {
        child1 = doc;
        assert.equal(doc.lft, 2);
        assert.equal(doc.rgt, 3);
        return done();
      });
    });
    it('should make sure root has been updated', function(done) {
      return wongo.findById('MockHierarchy', root._id, function(err, doc) {
        root = doc;
        assert.equal(doc.lft, 1);
        assert.equal(doc.rgt, 4);
        return done();
      });
    });
    it('should add a child to the child', function(done) {
      child11 = {
        name: 'child11'
      };
      return wongo.ns.addNode('MockHierarchy', child11, child1._id, function(err, doc) {
        child11 = doc;
        assert.equal(doc.lft, 3);
        assert.equal(doc.rgt, 4);
        return done();
      });
    });
    it('should make sure child1 has been updated', function(done) {
      return wongo.findById('MockHierarchy', child1._id, function(err, doc) {
        child1 = doc;
        assert.equal(doc.lft, 2);
        assert.equal(doc.rgt, 5);
        return done();
      });
    });
    it('should make sure root has been updated', function(done) {
      return wongo.findById('MockHierarchy', root._id, function(err, doc) {
        root = doc;
        assert.equal(doc.lft, 1);
        assert.equal(doc.rgt, 6);
        return done();
      });
    });
    it('should get all ascendants of child11', function(done) {
      return wongo.ns.findAncestors('MockHierarchy', child11._id, function(err, ancestors) {
        var ancestor, _i, _len;
        assert.ok(ancestors);
        assert.equal(ancestors.length, 2);
        for (_i = 0, _len = ancestors.length; _i < _len; _i++) {
          ancestor = ancestors[_i];
          if (ancestor.name !== 'Root' && ancestor.name !== 'child1') {
            assert.ok(false);
          }
        }
        return done();
      });
    });
    it('should get all descendants of root', function(done) {
      return wongo.ns.findDescendants('MockHierarchy', root._id, function(err, descendants) {
        var descendant, _i, _len;
        assert.ok(descendants);
        assert.equal(descendants.length, 2);
        for (_i = 0, _len = descendants.length; _i < _len; _i++) {
          descendant = descendants[_i];
          if (descendant.name !== 'child11' && descendant.name !== 'child1') {
            assert.ok(false);
          }
        }
        return done();
      });
    });
    it('should get all children of root', function(done) {
      return wongo.ns.findChildren('MockHierarchy', root._id, function(err, children) {
        assert.ok(children);
        assert.equal(children.length, 1);
        assert.equal(children[0].name, 'child1');
        return done();
      });
    });
    it('should try to remove child1 and fail', function(done) {
      return wongo.ns.removeNode('MockHierarchy', child1._id, function(err) {
        assert.equal(err != null ? err.message : void 0, 'Can not remove a node that has children.');
        return done();
      });
    });
    it('should remove child11', function(done) {
      return wongo.ns.removeNode('MockHierarchy', child11._id, function(err) {
        assert.ok(!err);
        return wongo.ns.findDescendants('MockHierarchy', child1._id, function(err, descendants) {
          assert.equal(descendants != null ? descendants.length : void 0, 0);
          return done();
        });
      });
    });
    return it('should not remove a child that is not in the tree', function(done) {
      return wongo.ns.removeNode('MockHierarchy', child11._id, function(err) {
        assert.equal(err != null ? err.message : void 0, 'Can not remove a node not in the nested set.');
        return done();
      });
    });
  });

}).call(this);
