# require
error = require 'elib/error'

# related
resource = require './resource'
middleware = null

# our resources
resources = {}

# bootstrap json-api
options = {}
module.exports.bootstrap = (input) ->
    # store options
    options = input

    # bootstrap response
    require('elib/json-api/response')(options)

    # initialize the middleware
    middleware = require('elib/json-api/middleware')(options)

# common middleware
module.exports.middleware = ->
    middleware

# define a type
module.exports.define = (type, Model) ->
    # adapter known?
    #throw new error.InvalidState() unless options.adapter?

    # create resource
    resources[type] = resource type, Model

# retrieve the resource
module.exports.resource = (type) ->
    resources[type]