assert = require 'assert'
wongo = require '../lib/wongo'


wongo.schema 'MockAuthor', 
  fields:
    name: String
    postIds: [{type: String, ref: 'MockPost', populateAlias: 'posts'}]

wongo.schema 'MockPost', 
  fields: 
    name: String
    author_ref: {type: String, ref: 'MockAuthor', populateAlias: 'author'}

describe 'Wongo Populate', ->
    
  author = {name: 'MeowMan'}
  posts = [
    {name: 'Woof Woof No More!'}
    {name: 'Kitty Kat Get Back'}
  ]
  
  it 'should be able to save author', (done) ->
    wongo.save 'MockAuthor', author, (err, result) ->
      assert.ifError(err)
      assert.ok(result._id)
      author = result
      done()
  
  it 'should be able to save posts', (done) ->
    post.author_ref = author._id for post in posts
    wongo.save 'MockPost', posts, (err, result) ->
      assert.ifError(err)
      assert.ok(result[0]._id and result[1]._id)
      posts = result
      done()
  
  it 'should be able to save author posts', (done) ->
    author.postIds ?= []
    author.postIds.push(post._id) for post in posts
    wongo.save 'MockAuthor', author, (err, result) ->
      assert.ifError(err)
      assert.equal(result.postIds?.length, 2)
      done()
  
  it 'should be able to find author and populate posts', (done) ->
    query = {where: {}, populate: 'posts'}
    wongo.find 'MockAuthor', query, (err, result) ->
      assert.ifError(err)
      assert.equal(result[0].posts[0].name, 'Woof Woof No More!')
      assert.equal(result[0].posts[1].name, 'Kitty Kat Get Back')
      done()
      