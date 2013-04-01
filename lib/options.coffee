
hooks = require __dirname + '/hooks'

#
# These are the default options and config for wongo
#
module.exports = 
  prune: hooks.prune
  applyDefaults: hooks.applyDefaults
  validate: hooks.validate
  generateSubdocIds: hooks.generateSubdocIds
  #loadDocumentBeforeRemove: hooks.loadDocumentBeforeRemove
  

