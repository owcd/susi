_ = require 'underscore'

# Construct the error objects - see http://bjb.io/development/2012/05/06/an-argument-against-subclassing-error.html
_.each ['PermissionDenied', 'Unauthorized', 'ObjectNotFound', 'InvalidArgument', 'InvalidState', 'NoContent'], (name) ->

    module.exports[name] = (msg, details) ->
        self = new Error msg
        self.name = name
        self.details = details
        self.__proto__ = module.exports[name].prototype
        self

    module.exports[name].prototype.__proto__ = Error.prototype
