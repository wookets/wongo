#
# All registered internal middleware
#

exports.applyDefaults = require __dirname + '/applyDefaults'
exports.populate = require __dirname + '/populate'
exports.prune = require __dirname + '/prune'
exports.generateSubdocIds = require __dirname + '/subdocId'
exports.validate = require __dirname + '/validate'
