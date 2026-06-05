Promise = require 'bluebird'
request = require 'request-promise'
rqf = require 'rqf'
_ = require 'underscore'

# server config
serverConfig = rqf 'server.config'

# error
error = require 'elib/error'

# authentication request
auth = (url, headers, body) ->
    # try
    Promise.try( ->
        url = "#{serverConfig.server.elms}/#{url}"
        options =
            json: true
            url: url
            headers: headers
            form: body

        # post request
        request.post(options)
    )

# pipe request to elms
pipe = (req, res, url, access_token) ->
    # try
    Promise.try( ->
        # build request
        elmsReq = initRequest url, access_token

        # pipe request
        req.pipe(elmsReq).pipe(res)
    )

# does a request to elms
doRequest = (url, options, access_token) ->
    # init options
    options = {} unless options?

    # default to json request
    options.json = true unless _.has(options, 'json')

    # set url
    options.url = url

    # build request
    elmsReq = initRequest options, access_token

    # attach headers
    elmsReq


# prepare a request to elms
initRequest = (options, access_token) ->
    # init options
    options = {url: options} unless _.isObject(options)

    # url given?
    options.url = "#{serverConfig.server.elms}/#{options.url}" if options.url?

    # remove accept encoding from headers of this request
    delete options.headers['accept-encoding'] if options.headers?['accept-encoding']?

    # locale given?
    if options.locale?
        options.headers = {} unless options.headers?
        options.headers['accept-language'] = options.locale
        delete options.locale

    # init request
    elmsReq = request options

    # auth?
    if access_token?
        elmsReq = elmsReq.auth null, null, true, access_token

    # return request
    elmsReq

# this is used for sending post urlencoded request
# exports
module.exports.auth = auth
module.exports.pipe = pipe

# export methods
_.each ['get', 'post', 'put', 'delete'], (method) ->
    module.exports[method] = (url, options, access_token) ->
        # init options
        options = {} unless options?
        options.method = method

        # does the request
        doRequest url, options, access_token
