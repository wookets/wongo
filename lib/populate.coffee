#
# Adds populate support for find queries.
# This is different from mongoose, because it allows you to define a populateAlias
# examples:
# authorIds: [{type: String, ref: 'Author', populateAlias: 'authors'}] // create a new property 'authors'
# authors: [{type: ObjectID, ref: 'Author', populateAlias: 'authors'}] // overwrite property (like mongoose)
# author: {type: String, ref: 'Author', populateAlias: 'authorObj'} // create a new property 'authorObj'
#


#
# Will normalize a populate string or array into an object
# e.g. 'author' becomes {author: {}}
# e.g. 'author post' becomes {author: {}, post: {}}
#
exports.normalize = (populate) -> 
  # if undefined
  if _.isUndefined(populate) or _.isNull(populate) or _.isEmpty(populate) then return {}
  # if string
  if _.isString(populate)
    pop = {}
    if populate.indexOf(' ') isnt -1
      pop[populate] = {}
    else
      for pop_i in populate.split(' ')
        pop[pop_i] = {}
    populate = pop
  # if object, just return
  return populate

