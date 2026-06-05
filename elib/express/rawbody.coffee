# libraries
_ = require 'underscore'
typeis = require 'type-is'
getRawBody = require 'raw-body'

# adds rawbody element to request
module.exports = (options) ->
    options ?= {}
    options.exclude ?= ['json', 'urlencoded', 'multipart', 'application/vnd.api+json']
    (req, res, next) ->
        req.rawBody = null
        if typeis(req, options.exclude) is false
            getRawBody(req,
                length: req.headers['content-length']
                limit: '16mb'
            , (err, buffer) ->
                unless err
                    req.rawBody = buffer
                    next()
                else
                    next err
            )
        else
            next()
