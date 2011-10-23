qs = require('qs')
request = require 'request'
kue = require('kue')    
jsdom = require('jsdom').jsdom
jobs = kue.createQueue()
redis = require('redis-url').createClient process.env.REDISTOGO_URL 
_         = require 'underscore'
_.mixin     require 'underscore.string' 

jobs.process 'fetch', (job, done) ->     
  console.log job.data.url
  request {uri: job.data.url}, (error, response, body) ->
    #console.log response.body
    #if response.body
    #  dom =  jsdom body, null, { 
    #          FetchExternalResources: false,
    #          ProcessExternalResources: false,
    #          MutationEvents: false,
    #          QuerySelector: false
    #        }
    #  console.log dom
    #  done()
    console.log body.match(/<title>(.*?)<\/title>/)[1]
  true

kue.app.listen 5001

  #redis.hgetall(code, (err, record)->
  #  if err
  #    response.render 'error.jade'
  #  else if record.private is no or authenticate(request, response)    
  #    response.redirect record.url
  #    redis.hset code, 'hits', record.hits + 1
  #)
  