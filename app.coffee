app   = require('./index').app
port  = process.env.PORT or 3000

app.listen port, ->
  console.log "Application listening on #{port}..."
