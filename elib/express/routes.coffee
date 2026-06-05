parseUrl = require 'parseurl'

module.exports = ->
    (req, res, next) ->
        reqMethod = req.method.toLowerCase()

        # this is a dirty fix to figure out the matched route until we find another way
        path = parseUrl(req).pathname
        for layer in req.app._router.stack
            if layer.match(path) and layer.route? and layer.route.methods[reqMethod]
                req.route = layer.route.path
                break

        next()