#
# All registered internal middleware
#

exports.applyDefaults = require __dirname + '/applyDefaults'
exports.populate = require __dirname + '/populate'
exports.prune = require __dirname + '/prune'
stringizeObjectID = require __dirname + '/stringizeObjectID'
exports.stringizeObjectIDBeforeSave = stringizeObjectID.beforeSave
exports.stringizeObjectIDAfterSave = stringizeObjectID.afterSave
exports.stringizeObjectIDBeforeFind = stringizeObjectID.beforeFind
exports.stringizeObjectIDAfterFind = stringizeObjectID.afterFind
exports.generateSubdocIds = require __dirname + '/subdocId'
exports.validate = require __dirname + '/validate'
