Dogo = {}
express   = require 'express'
redis     = require('redis-url').createClient process.env.REDISTOGO_URL 
everyauth = require 'everyauth'
connect   = require 'connect'                
stitch    = require 'stitch'
_         = require 'underscore'
_.mixin     require 'underscore.string'      
# db        = require('Redback')(redis)

Dogo.Utils = require './utils'

everyauth.debug = true                        

everyauth.google
  .appId('300861864070.apps.googleusercontent.com')
  .appSecret('n89AsWS21QV5mH5xQGBFrbvE')
  .scope('https://www.google.com/m8/feeds') # What you want access to
  .myHostname('http://localhost:3000')
  .findOrCreateUser((session, accessToken, accessTokenExtra, googleUserMetadata) ->
    if _.endsWith(googleUserMetadata.id, "@do.com") then googleUserMetadata else @Promise().fail("The account #{googleUserMetadata.id} is not authorized to login.")
  )
  .redirectPath('/')   
  
app = express.createServer(
  express.logger()
  express.bodyParser()
  express.cookieParser()
)     
RedisStore = require('./redis-store')(express)          
app.set 'views', __dirname + '/views'
app.use express.static(__dirname + '/public')
app.use express.session({secret: 'dsafsdfasdf', store: new RedisStore(redis)})
app.use express.methodOverride()
app.use everyauth.middleware()     
app.use(app.router)                
app.use express.compiler
  src: __dirname + '/client', 
  dest: __dirname + '/public',
  enable: ['coffeescript']
  
requireAuth = (request, response, next) ->
  if Dogo.user = request?.session?.auth?.userId
    next()
  else  
    response.redirect '/auth/google'

authenticate = (request, response) ->
  user = request?.session?.auth?.userId
  unless user
    response.redirect('/auth/google')
    return false
  user
    
package = stitch.createPackage
  paths: ["#{__dirname}/client"]          
  
app.get '/package.js', package.createServer()
    
app.get '/authed?', (request, response) ->
  console.log request?.session?.auth?.userId
  response.send "0"   
  
app.get '/', (request, response) ->
  response.render 'index.jade'  
  
app.get '/:code', (request, response) ->
  code = request.params.code   
  redis.hgetall(code, (err, record)->
    if err
      response.render 'error.jade'
    else if record.private is no or authenticate(request, response)    
      response.redirect record.url
      redis.hset code, 'hits', record.hits + 1
  )      

app.get '/shorten/:url', requireAuth, (request, response) ->
  trys = 0   
  saved = no                  
  destination =
    hits: 0
    creator: Dogo.user 
    private: request.params.private || false

  until saved or trys > 10
    code = Dogo.Utils.randomString(3)
    if saved = redis.hsetnx(code, 'url', Dogo.Utils.normalizeLink(request.params.url))
        redis.hmset code, destination                         
    trys++         
    
  response.send "Success in the cloud. http://go.do/#{code}"          
  

redis.set('foo', 'bar');

redis.get 'foo', (err, value) ->
  console.log('foo is: ' + value)   

      
port = process.env.PORT || 3000
everyauth.helpExpress(app)
app.listen port, ->
  console.log("Listening on " + port) 
  
  