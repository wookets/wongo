#
# All registered crud fucntions
#
save = require __dirname + '/save'
exports.save = save.save

remove = require __dirname + '/remove'
exports.remove = remove.remove
exports.clear = remove.clear

find = require __dirname + '/find'
exports.find = find.find
exports.findOne = find.findOne
exports.findById = find.findById
exports.findByIds = find.findByIds
