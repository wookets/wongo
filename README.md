# Wongo

Wongo is a mongoose.js wrapper that unwraps certain ORM functionality in an attempt to reduce code, increase predictibility and tweak functionality. 

A wrapper that unwraps a wrapper. Crazy right?

Disclaimer: This project is extremely immature, but feel free to take a peek around and be critical. 

## Quick Example

```coffeescript
# find example
query = {where: {name: 'mint'}}
wongo.find 'Mock', query, (err, docs) ->
  # docs is a raw json array of objects - i.e. it uses lean()

# save example
document = {name: 'mint'}
wongo.save 'Mock', document, (err, doc) ->
  # doc is a raw json object
  
# schema definition example
wongo.schema = 'Mock',
  fields: 
    name: String
    
  plugins: 
    'my existing mongoose plugin': [plugin_ref, {option1: 'meow'}]
  
  hooks:
    beforeSave: (document, next) ->
      # do something to the document before it is saved (will be a json doc, not a mongoose ORM doc)
      next()
    
    afterSave: (document, next) ->
      # do something to the document after it is saved (note, this allows async unlike mongoose)
      next()
  
```

Want more examples? Check out the tests folder or just fill out an issue or ask. 

## Changelog

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

