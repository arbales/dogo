qs = require('qs')
request = require 'request'
kue = require('kue')
jsdom = require('jsdom').jsdom
jobs = kue.createQueue()
redis = require('redis-url').createClient process.env.REDISTOGO_URL
_         = require 'underscore'
_.mixin     require 'underscore.string'

jobs.process 'fetch', 20, (job, done) ->
  request {uri: job.data.url}, (error, response, body) ->
    #if title = body.match(/<title>(.*?)<\/title>/)[1]
    try
      dom = jsdom body, null, 
        features:
          FetchExternalResources: no
          ProcessExternalResources: no
          MutationEvents: off
          QuerySelector: on
      window = dom.createWindow()

      if dom.title
        redis.hset job.data.code, 'title', dom.title
      if description = window.document.querySelector('meta[name=description]')?['content']
        redis.hset job.data.code, 'description', description
      done()
    catch err
      done(err)
  true

kue.app.listen 5001
