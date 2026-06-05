# libraries
_ = require 'underscore'
rqf = require 'rqf'

# configuration
serverConfig = rqf 'server.config'

# i18n
i18n = require 'elib/i18n'

# export
module.exports.assemble = (locale, segments, params) ->
    # query string module
    querystring = require 'querystring'

    # i18n
    translation = i18n locale

    # init url
    url = []

    # first segment is always the language
    url.push i18n.language locale

    # assemble url
    _.each segments, (segment) ->
        if segment.indexOf('_') >= 0
            url.push translation.translate(segment).fetch()
        else
            url.push segment

    # join
    url = url.join '/'

    # add params
    url += '?' + querystring.stringify(params) if _.size(params) > 0

    # return
    url

# create an absolute url based on protocol, host, locale and path
module.exports.absolute = (protocol, host, path = '/') ->
    # url module
    url = require 'url'

    # leading slash
    path = '/' + path unless path[0] is '/'

    # default site
    url.format(
        protocol: protocol
        host: host
    ) + path