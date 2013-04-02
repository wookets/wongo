# Wongo

Wongo is an ODM-like library intended to simplify working with mongodb. The intent is to have feature parity with mongoosejs, but simplier and cleaner. Part of that simplicity is only supporting three crud methods; save, remove, and find which should cover 99% of use cases. Of course, if you want to get down and dirty, the native mongodb driver is exposed. 

* [Installation](#installation)
* [Usage](#usage)
* [Schema](#schema)
* [Queries](#queries)
* [Middleware](#middleware)
* [Populate](#populate)
* [Plugins](#plugins)

## Installation
```
npm install wongo
```

## Usage

### Require the module
```coffeescript
wongo = require 'wongo'
```

### Connect to the database
```coffeescript
wongo.connect(url)
```

### Define a basic schema
```coffeescript
wongo.schema = 'Mock',
  fields: 
    name: String
    createdOn: Date
```

### Save a document 
```coffeescript
doc = {name: 'Woof'}
wongo.save 'Mock', doc, (err, result) -> # result is the saved raw json object
```

### Save a lot of documents
```coffeescript
wongo.save 'Mock', documents, (err, result) -> # result is the saved json object array
```

### Update a document
```coffeescript
partialDoc = {_id: '5', name: 'Wallace'}
where = {name: 'Gromit'}
wongo.save 'Mock', partialDoc, where, (err, result) -> 
```

### Update a lot of documents
```coffeescript
documents = [{name: 'bil'},{name: 'sig'},{name: 'boo'}]
where = {accountId: '65'}
wongo.save 'Mock', documents, where, (err, result) -> 
```

### Find documents
```coffeescript
query = {name: 'mint'}
wongo.find 'Mock', query, (err, docs) -> # docs is a raw json array of objects
```

### Remove a document
```coffeescript
document = {_id: 'uniqueId'}
wongo.remove 'Mock', document, (err) -> # doc has been removed
```
### Remove a document by _id
```coffeescript
documentId = 'uniqueId'
wongo.remove 'Mock', documentId, (err) -> # doc has been removed
```

## Schema
Just like mongoosejs, everything starts with a Schema. Schemas map to collections in mongodb. 
Supported Property Types:
* String
* Number
* Date
* Boolean
* ObjectID
* Array

Setting a {type: 'mixed'} on a schema field wongo will just assume you are going to handle the type. 
This means, pruning will leave the field, it will not look for validation, or otherstuff. 'mixed' is just an 
example, you could name it anything and then write a plugin which will do something with it. Or extend 
the validator to validate against it. 

### A 'complete' schema
```coffeescript
wongo.schema = 'Mock',
  fields:                                            # fields acts just like the normal mongoose schema
    name: {type: String}
    embeddedDocArray: [                              # embedded docs and everything are just like mongoose
      name: String
      validia: {type: Number, min: 3, max: 9, required: true}
    ]
    createdOn: {type: Date, required: true}
  
  hooks:                                          # participate in middleware
    beforeSave: (document, schema, next) ->       # document is a json doc
    afterSave: (document, schema, next) ->        # note, this allows async unlike mongoose
    validate: (document, schema, next) ->         # we can even override wongo's validation with our own
    prune: false                                  # or set the pruner to false if we dont want wongo to trim our documents
    beforeFind: (query, schema, next) ->          # modify a find query before it is run
    afterFind: (query, schema, documents, next) -># after we find a group of documents, we can do something with them
    beforeRemove: (document, schema, next) ->
    afterRemove: (document, schema, next) ->
    
  indexes: [                              # add standard mongodb compliant indices
    {name: 1}
    [{name: 1}, {unique: true}]           # use an array to pass in index options
  ]
```

### Validation
Validation should hold feature parity with mongoose.js 


## Queries
There are four support find methods:
* find(_type, query, callback)
* findOne(_type, query, callback)
* findById(_type, _id, callback)
* findByIds(_type, _ids, callback)

### The query object
```
query = {select: '_id name', where: {name: 'Moo'}, limit: 5}
```
The query object has the following top-level properties.
* select
* where
* sort
* limit
* skip
* populate

If 'where' isn't found, wongo wraps the query object in a where statement. 
```
query = {name: 'Boo'}
```
is equivalent to 
```
query = {where: {name: 'Boo'}}
```


## Middleware
Middleware is defined on the schema (under the hooks property) or in the wongo.options. Middleware
is pushed into an array when the schema is registered. So, post schema registration, if you want to 
add more middleware, you need to add it directly to the array. Examples of this are shown in the plugins
module. 


### Hooks defined on the schema
```coffeescript
wongo.schema = 'Mock',
  hooks:                                          
    beforeSave: (document, schema, next) ->       
    afterSave: (document, schema, next) ->        # add your own handler for what happens after a save
    validate: true                                # will use default wongo validator
    prune: false                                  # turns off the wongo pruner
    beforeFind: (query, schema, next) ->          
    afterFind: (query, schema, documents, next) ->
    beforeRemove: (document, schema, next) ->
    afterRemove: (document, schema, next) ->
```

### Hooks defined globally
These will override internal wongo middleware, but won't override locally defined middleware. 
```coffeescript
wongo.options.prune = false
wongo.options.validate = (document, schema, callback) ->
  # implement your own validate method for all your schemas
```

### Bundled Middleware (enabled by default)
* applyDefaults - Will allow you define 'default:' on your schemas and apply it beforeSave.
* prune - aka mongoose 'strict' mode. Will remove any properties from objects not defined on your schema.
* generateSubdocIds - Will generate ObjectIDs for subdocuments like mongoose does.
* validate - Will validate a document against a schema before saving.
* populate - Adds afterFind support for running more queries to populate properties

## Populate

## Plugins
Plugins work similar to mongoose, though they aren't compatible, because the schema object will be different. 

### Plugin example
Here is an example of a plugin which adds createdOn and modifiedOn to the schema and also 
adds before middleware save functionality. Note, that unshift is used to apply the middleware before
validation. 
```coffeescript
# Addes a modifiedOn and createdOn timestamp to a schema and updates beforeSave.
module.exports = (schema, options) ->
  # add fields to schema
  schema.fields.createdOn = {type: Date, required: true}
  schema.fields.modifiedOn = {type: Date, required: true}
  # add beforeSave middleware
  schema.middleware.beforeSave.unshift (document, schema, callback) ->
    document.createdOn ?= new Date()
    document.modifiedOn = new Date()
    callback()
```

### Bundled Plugins (not enabled by default)
* timestamp - Adds createdOn and modifiedOn and adds beforeSave middleware
* nestedset - Adds lft, rgt, parentId to a schema and adds query functions to the wongo object


## More Examples?

Want more examples? Check out the tests folder or just fill out an issue and ask. 

## Changelog

### 6.0 
* Added plugin support

### 5.0
* Added populate support
* Compiled to JS 
* Better organization
* Full hook override array que support for save, find, and remove
* Nixed removeAll and saveAll

### 4.0 
* Completely ditched mongoose.js. When I first started this project I always thought about it, since mongoose is like a big ogre. I finally feel 'semi' comfortable taking on the direct approach and working directly with the native mongodb driver. 
* Rewrote everything and every test. There are currently over 50 tests, I'm imagining this number will grow to 200+ before the day is done.
* Basic schemas and queries all work. Still needs a lot of work ironing out many more detailed features to bring it inline and then go past mongoose's feature set. The goal is not to directly replicate everything in mongoosejs, but to take what is good and makes sense. 

### 3.0 
* Added indexes and options to wongo.schema.
* Moved mongoose as a dependency 
* A few cleanups of util methods

### 2.0 
* Added wongo.schema if you want a different way to define your schema. 
* Added wongo hooks; these work outside of existing mongoosejs middleware, because I wanted to do things differently. For example, being able to work with the raw json document before it is cast to a mongoose ORM document. 

### 1.0 
* Initial library with support for save / find / remove methods.


## Why

This library was created because I was annoyed by the little things in mongoosejs. 

Disclaimer: Before I get into the annoyances, mongoosejs is a terrific library. Nothing really comes close to it in terms of feature set, so the point of this project is not to reinvite the wheel, but to make it fit on my car. If you're driving a truck, you shouldn't use this library. 

* Property values on objects would sometimes randomly disappear after a find. Using a doc.get('prop') fixed the problem, but wtf? This is one of those annoyances with ODM or ORM libraries where your json objects turn into 'magic' beans with various quirks in them. I created this library so you could work with MongoDB, define a schema, but just work with native JSON data objects and not have magic methods or properties added and removed. Essentially, documents dont have lifecycles, they are just dumb data documents. 
* Mongoosejs recently fixed using lean() on populate queries and in general. Wongo never messes with your data documents, so there will never be a 'lean()' problem... ever.
* I have a very personal distain for the active record pattern. It is nice to do resource.save() and not bring in another import / require statement, but you still need to do mongoose.model('') to get the 'model'... And then you have to worry about, what state is this data object in? My point is, let's just let data be data and business logic not be defined directly on the data document. 
* The other reason I don't like the active record pattern... I worked next to a company that had an 'active record pattern domain model' java class that was 10,000 lines of code. What a mess. 
* Populate and depopulate are great in mongoose. However, I wanted something better and less 'oh, lets just override a property with an object and then go back in and save that object and have a potential mess.' So, in wongo, populate aliases can be defined on the schema. If you want to populate accountIds, you can do that, but you can also have it stick the account documents in the accounts property. 


## Running the Tests

I use mocha. So, you should be able to run the 'mocha' command in the project folder and be done. However, you will need to add a db_config.json file that has the db_config.url parameter in it. This file is not committed to git for obvious reasons. 

Here is a format you can use:

test/db_config.json

```javascript
{
"url": "mongodb://{username}:{password}@{host}:{port}/{db}"
}
```

