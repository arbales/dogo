express   = require 'express'
redis     = require('redis-url').createClient process.env.REDISTOGO_URL 
everyauth = require 'everyauth'
connect   = require 'connect'      
_         = require 'underscore'
_.mixin     require 'underscore.string'

app = express.createServer express.logger() 
everyauth.debug = true                        

everyauth.google
  .appId('300861864070.apps.googleusercontent.com')
  .appSecret('n89AsWS21QV5mH5xQGBFrbvE')
  .scope('https://www.google.com/m8/feeds') # What you want access to
  .myHostname('http://localhost:3000')
  .findOrCreateUser((session, accessToken, accessTokenExtra, googleUserMetadata) ->
    # find or create user logic goes here
    # Return a user or Promise that promises a user
    # Promises are created via
    console.log googleUserMetadata
    if (_ googleUserMetadata.id).endsWith "@do.com"
      return googleUserMetadata
    else                       
      this.promise.reject()
  )
  .redirectPath('/')

app.get '/', (request, response) ->
  response.send "Hello"
  


redis.set('foo', 'bar');

redis.get 'foo', (err, value) ->
  console.log('foo is: ' + value)   
  
app.use express.methodOverride()
app.use express.bodyParser()
app.use express.cookieParser()
app.use express.session({secret: 'dsafsdfasdf'})
app.use app.router   
app.use everyauth.middleware()

      
port = process.env.PORT || 3000
app.listen port, ->
  everyauth.helpExpress(app)
  console.log("Listening on " + port) 
  
  