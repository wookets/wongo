//@ sourceMappingURL=embed.test.map
// Generated by CoffeeScript 1.6.1
(function() {
  var assert, wongo;

  assert = require('assert');

  wongo = require('../lib/wongo');

  wongo.schema('MockEmbed', {
    fields: {
      name: String,
      child: {
        name: String,
        child: {
          name: String
        }
      },
      children: [
        {
          name: String,
          children: [
            {
              name: String
            }
          ]
        }
      ]
    }
  });

  describe('Wongo Embedded', function() {
    var doc;
    doc = {
      name: 'KingMeow',
      child: {
        name: 'KitMeow',
        child: {
          name: 'KittyMeow'
        }
      },
      children: [
        {
          name: 'KitcMeow',
          children: [
            {
              name: 'SubKitchMeow'
            }, {
              name: 'SubKitchMeow2'
            }
          ]
        }, {
          name: 'KitcMeow2',
          children: []
        }
      ]
    };
    return it('should be able to save an embedded document', function(done) {
      return wongo.save('MockEmbed', doc, function(err, result) {
        assert.ifError(err);
        assert.ok(result != null ? result._id : void 0);
        doc = result;
        assert.equal(doc.name, 'KingMeow');
        assert.equal(doc.child.name, 'KitMeow');
        assert.ok(doc.child._id);
        assert.equal(doc.child.child.name, 'KittyMeow');
        assert.equal(doc.children.length, 2);
        assert.equal(doc.children[0].name, 'KitcMeow');
        assert.equal(doc.children[1].name, 'KitcMeow2');
        assert.equal(doc.children[0].children.length, 2);
        return done();
      });
    });
  });

}).call(this);