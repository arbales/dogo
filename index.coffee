Dogo = {}
express   = require 'express'
redis     = require('redis-url').createClient process.env.REDISTOGO_URL
everyauth = require 'everyauth'
connect   = require 'connect'
stitch    = require 'stitch'
_         = require 'underscore'
_.mixin     require 'underscore.string'
jobs       = require('kue').createQueue()
# db        = require('Redback')(redis)

Dogo.Utils = require './utils'

everyauth.debug = true

everyauth.google
  .appId('300861864070.apps.googleusercontent.com')
  .appSecret('n89AsWS21QV5mH5xQGBFrbvE')
  .scope('https://www.google.com/m8/feeds') # What you want access to
  ##.loginView('login')
  .findOrCreateUser((session, accessToken, accessTokenExtra, googleUserMetadata) ->
    if _.endsWith(googleUserMetadata.id, "@do.com")
      #promise.fulfill googleUserMetadata
      googleUserMetadata
    else
      "Failure"
    #promise.fail("The account #{googleUserMetadata.id} is not authorized to login.")
    #promise
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

authenticated = (request, response) ->
  authed = request?.session?.auth?.userId

authenticate = (request, response) ->
  authed = authenticated(request, response)
  if not authed
    request.session['redirectPath'] = "/test"
    response.redirect '/auth/google'
  authed



package = stitch.createPackage
  paths: ["#{__dirname}/client"]

app.get '/package.js', package.createServer()

app.get '/authed?', (request, response) ->
  console.log request?.session?.auth?.userId
  response.send request?.session?.auth?.userId

app.get '/', (request, response) ->
  response.render 'index.jade'

app.get '/info/:code', (request, response) ->
  code = request.params.code
  redis.hgetall(code, (err, record)->
    if err
      response.render 'error.jade'
    else if record.private is no or authenticate(request, response)
      response.render 'info.jade', locals:
        url: record.url
        creator: record.creator
        hits: record.hits
        code: code
        title: record.title || false
        private: record.private
        description: record.description || "-"
  )

app.get '/:code', (request, response) ->
  code = request.params.code
  redis.hgetall(code, (err, record)->
    if err
      response.render 'error.jade'
    else if record.private is no or authenticate(request, response)
      if request.accepts 'application/json'
        # response.contentType 'json'
        console.log record
        response.json record
      else
        response.redirect record.url
      redis.hset code, 'hits', record.hits + 1
  )

app.post '/shorten', requireAuth, (request, response) ->
  url = Dogo.Utils.normalizeLink(request.body.url)
  code = false
  saved = no
  length = if request.body.longLink is 'on' then 44 else 3
  destination =
    hits: 0
    creator: Dogo.user
    private: request.body.private == 'on'
  if not request.body.url
    response.redirect '/'
    return false

  persist = (length) ->
    trys = 0
    until saved or trys > 10
      code = Dogo.Utils.randomString(length)
      if saved = redis.hsetnx(code, 'url', url)
          redis.hmset code, destination
      trys++

  until saved
    persist(length)
    length++

  jobs.create('fetch',{
    url: url
    code: code
  }).save()

  response.redirect "/info/#{code}"

port = process.env.PORT || 3000
everyauth.helpExpress(app)

app.listen port, ->
  console.log("Listening on " + port)


