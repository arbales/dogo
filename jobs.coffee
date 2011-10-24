qs        = require('qs')
request   = require 'request'
kue       = require('kue')
jsdom     = require('jsdom').jsdom
jobs      = kue.createQueue()
redis     = require('redis-url').createClient()# process.env.REDISTOGO_URL
_         = require 'underscore'
_.mixin     require 'underscore.string'
utils     = require './utils'
URL       = require 'url'  
Path      = require 'path'  
fs        = require 'fs' 
#Hash      = require('mhash').hash

jobs.process 'downloadImage', (job, done) -> 
  url = job.data.url                   
  code = job.data.code
  name = URL.parse(url).pathname.replace /\//g, "-"          
  request(url).pipe(fs.createWriteStream("./files/#{code}-#{name}"))

jobs.process 'fetch', 5, (job, done) ->
  request {uri: job.data.url}, (error, response, body) ->
    try
      dom = jsdom body, null, 
        features:
          FetchExternalResources: no
          ProcessExternalResources: no
          MutationEvents: off
          QuerySelector: on
      
      window = dom.createWindow()
      redis.hset(job.data.code, 'title', dom.title) if dom.title
                                        
      if images = window.document.querySelectorAll('img')  
        for image in images
          url = URL.resolve(job.data.url, image.src) 
          jobs.create('downloadImage',
            url: url 
            code: job.data.code
          ).save()
        
      if description = window.document.querySelector('meta[name=description]')?['content']
        redis.hset job.data.code, 'description', description

      done()      
    catch err
      done(err)      
  true

port = process.env.PORT or 3000
kue.app.listen port, ->
  console.log "Kue listening on #{port}..."