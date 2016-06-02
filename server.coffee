express = require('express');
Promise = require 'bluebird'
compress = require('compression');
session = require 'express-session'
bodyParser = require 'body-parser'
rawParser = require 'elib/express/rawbody'
load = require 'express-load'
logger = require('morgan');
errorHandler = require('errorhandler');
#lusca = require('lusca');
#dotenv = require('dotenv');
path = require('path');
hbs = require 'hbs'
rqf = require 'rqf'
fs = Promise.promisifyAll require 'fs'
#passport = require('passport');
#multer = require('multer');
#upload = multer({ dest: path.join(__dirname, 'uploads') });

# load the configuration
config = rqf 'config'

# create app
module.exports = app = express()

# create server
server = require('http').Server(app)
server.listen config.get('server.port'), config.get('server.ip'), ->
    console.log "Listening on #{config.get('server.port')}"

# set hbs view engine
app.set 'view engine', 'hbs'
app.set 'views', __dirname + '/views'
hbs.registerPartials __dirname + '/views/partials'

# view helpers
rqf('lib/handlebars/helpers')(hbs)

# compression
app.use compress()

# logging
app.use logger('dev')

# parsers
app.use rawParser()
app.use bodyParser.json
    type: ['application/json', 'application/vnd.api+json']
app.use bodyParser.urlencoded
    extended: true

# session
app.use session(
    name: config.get('session.name')
    resave: false
    saveUninitialized: false
    secret: config.get('session.secret')
)

# serve static files
app.use express.static('client/dist/',
    dotfiles: 'ignore'
    etag: true
    extensions: ['htm', 'html']
    index: []
    maxAge: '365d'
    redirect: false
    setHeaders: (res, p) ->
        # correct res type for .map files
        res.type 'application/json' if path.extname(p) is '.map'

        # add cache control header, mainly no-transform to prevent
        # content transformation by proxies, it could cause file
        # corruption.
        res.set 'Cache-Control', 'public, no-transform, max-age=31536000'
)

# rev
app.use (req, res, next) ->
    # default revision
    res.locals.rev = Math.round(+Date.now() / 1000)

    # get last modified time of main file, changes with each rebuild
    fs.statAsync('client/dist/assets/susi.js').then((stat) ->
        res.locals.rev = Math.round(stat.mtime.getTime() / 1000)
    ).finally( ->
        next()
    )

# db
models = rqf 'models'
#app.use(passport.initialize());
#app.use(passport.session());

# api
api = express()

# json api middleware
jsonApiMiddleware = rqf('lib/express/jsonApi')(
    models: models
)

# use request middleware
api.use jsonApiMiddleware

# load all controllers and routes
load('controllers'
    extlist: /\.coffee$/
    cwd: __dirname + '/api'
).then('routes'
    extlist: /\.coffee$/
    cwd: __dirname + '/api'
).into(api)

# automatically register model routes
rqf('lib/express/routes/generic')(api, models)

# use error handling middleware
api.use jsonApiMiddleware.error

# mount api
app.use '/api', api

# load all controllers and routes
load('controllers'
    extlist: /\.coffee$/
    cwd: __dirname
).then('routes'
    extlist: /\.coffee$/
    cwd: __dirname
).into(app)

# init the speaker service
rqf('services/speaker')()

# for development environment
if config.get('env') is 'development'
    errorhandler = require 'errorhandler'
    app.use errorhandler()
