# Overview

I wrapper that actually unwraps a wrapper. Crazy right?

This library was created because I was annoyed by the little things in mongoosejs. 

* Why isn't a property showing up on a document after I do a query, but I use 'get' and pass in a string to get the value?
* Everything should be 'lean()'... I'm just going to pass the object up to the web layer, why worry about all that mapping. 
* I have a distain for the active record pattern. Look people, I get it... It's nice to do resource.save(), but it's also nice not to have a cluster of different functions and properties on my domain model. I personally prefer the dao method. But, hey, if you like the active record, keep using mongoose. There is nothing for you here. 
* The library includes a safer way to populate / depopulate certain things. It also (in the short future) has support for lean() populate queries. 


