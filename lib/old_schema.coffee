
# 
# Mongoose schema replacement
exports.schema = (_type, wschema) ->
  if wschema.options?._type 
    wschema.fields._type = {type: String, default: _type, required: true} # add _type
    delete wschema.options._type
  
  Schema = new mongoose.Schema(wschema.fields)
  
  # hooks (validate, beforeSave, afterSave
  for own prop, key of wschema.hooks ? {}
    Schema.statics[prop] = wschema.hooks[prop]

  # plugins
  for plugin in wschema.plugins ? []
    if _.isArray(plugin) 
      Schema.plugin(plugin[0], plugin[1])
    else 
      Schema.plugin(plugin)
  
  # indexes
  for index in wschema.indexes ? []
    if _.isArray(index) 
      Schema.index(index[0], index[1])
    else
      Schema.index(index)
  
  # options
  for own option, value of wschema.options ? {}
    Schema.set(option, value)
  
  Type = mongoose.model(_type, Schema)
  
  return Type
