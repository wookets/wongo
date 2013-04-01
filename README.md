# Wongo

Wongo is a mongodb wrapper intended to simplify working with the database. The intent is to have feature parity with mongoose where it makes sense.

It is written in coffeescript *cringe*, but does have over 60 mocha tests with more being added everyday. Previous versions were based on mongoose, but I have since taken to coding directly against native mongodb driver.

## Installation
```
npm install wongo
```

## Usage

1. Connect to mongodb
2. Define a schema
3. CRUD away

### Connect to the database

```coffeescript
wongo = require 'wongo'
wongo.connect(url)
```

### Define a Schema

```coffeescript
wongo.schema = 'Mock',
  fields:                                 # fields acts just like the normal mongoose schema
    name: String
    prop1: {type: Number, required: true}
    embedded: [                           # embedded docs and everything are just like mongoose
      name: String
    ]
    createdOn: Date
  
  hooks:                                  # participate in middleware
    save: 
      before: (document, next) ->         # document is a json doc
      after: (document, next) ->          # note, this allows async unlike mongoose
      validate: (document, schema) ->     # we can even override wongo's validation with our own
      prune: false                        # or set the pruner to false if we dont want wongo to trim our documents
    find: 
      before: (query, next) ->            # modify a find query before it is run
      after: (documents, next) ->         # after we find a group of documents, we can do something with them
    remove: 
      before: (document, next) ->
      after: (document, next) ->
    
  indexes: [                              # add standard mongodb compliant indices
    {name: 1}
    [{name: 1}, {unique: true}]           # use an array to pass in index options
  ]
```

### Run some Find and CRUD queries

```coffeescript
# find example
query = {where: {name: 'mint'}}
wongo.find 'Mock', query, (err, docs) ->
  # docs is a raw json array of objects - i.e. it uses lean()

# another find example (without where)
query = {name: 'min'}
wongo.find 'Mock', query, (err, docs) ->
  # docs is a raw json array of objects - i.e. it uses lean()

# save example
document = {name: 'mint'}
wongo.save 'Mock', document, (err, doc) ->
  # doc is a raw json object

# update example (still partakes in save middleware)
where = {_id: 'uniqueId'}
partialDocument = {age: 12}
wongo.update 'Mock', where, partialDocument, (err) ->
  # doc will be updated

# remove by _id example (still partakes in remove middleware)
documentId = 'uniqueId'
wongo.remove 'Mock', documentId, (err, doc) ->
  # doc has been removed by _id

# remove by doc example
document = {_id: 'uniqueId'}
wongo.remove 'Mock', document, (err, doc) ->
  # doc has been removed
```

Want more examples? Check out the tests folder or just fill out an issue and ask. 

## Changelog

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

Disclaimer: Before I get into the annoyances, mongoosejs is a terrific library. Nothing really comes close to it in terms of feature set, so the point of this project is not to reinvite the whell, but to make it fit on my car. If you're driving a truck, you shouldn't use this library. 

* Property values on objects would sometimes randomly disappear after a find. Using a doc.get('prop') fixed the problem, but why? Surely, there was a mongoosejs bug a foot. But, small little bugs like this in ORM / Active Record patterns are what makes you want to throw the whole thing out the window. Wongo Solution: it uses lean() and toObject() on everything. 
* mongoosejs ORM behavior can have devestating consequences on large data sets. Wongo Solution: use lean() on every query that returns an array of documents.  
* I have a very personal distain for the active record pattern. Look people, I get it... It's nice to do resource.save() and not bring in another import / require statement, but it is also nice not to have a cluster of different functions and properties on my domain model. 98% of which I will never even use. I prefer the data access object pattern. But, hey, if you like the active record, keep using mongoose. There is nothing for you here. Wongo Solution: every method has a _type as the first parameter, so you dont have to mongoose.model anything. Or rely on doc.save(), which recently broke on me in my other project. Again, weird ORM bugs. 
* Populate and depopulate are great in mongoose. However, there are some oddities. For example, if you populate a property and then later simply add an _id. Don't populate something, but add an object with an _id. There are some inconsistencies that wongo attempts to solve. Wongo Solution: before saving a resource, the schema is checked and depopulation is normalized if needed.


## Running the Tests

I use mocha. So, you should be able to run the 'mocha' command in the project folder and be done. However, you will need to add a db_config.json file that has the db_config.url parameter in it. This file is not committed to git for obvious reasons. 

Here is a format you can use:

test/db_config.json

```javascript
{
"url": "mongodb://{username}:{password}@{host}:{port}/{db}"
}
```

