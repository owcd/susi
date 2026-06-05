# libs
_ = require 'underscore'
rqf = require 'rqf'
Promise = require 'bluebird'
request = require 'request-promise'

# tools
error = require 'elib/error'

# The request timeout
timeout = 3000

# 20.10.2014
# - remove api.hostip.info/get_json.php?ip= (incorrect results)
# - remove api.codehelper.io/ips/?php&ip= (no results)

# 15.02.2016
# - remove http://www.telize.com/geoip/ (no free teer)

# Find host by ip
# @return promise
module.exports = (ip) ->
    # determine users ip address
    match = ip.match(/([0-9]{1,3}\.){3}[0-9]{1,3}/)
    throw new error.InvalidArgument('The supplied ip "' + ip + '" was invalid') unless match && !_.isEmpty(match)

    # resolve promises
    Promise.all([
        # freegeoip
        request.get(
            url: 'http://freegeoip.net/json/' + ip
            json: true
            timeout: timeout
        ).then((data) ->
            return unless data?
            {
                ip: ip
                country: data.country_code
                city: data.city
                longitude: data.longitude
                latitude: data.latitude
            }
        ).catch((err) -> null)

        # ip-api
        request.get(
            url: 'http://ip-api.com/json/' + ip
            json: true
            timeout: timeout
        ).then((data) ->
            return unless data?
            {
                ip: ip
                country: data.countryCode
                city: data.city
                longitude: data.lon
                latitude: data.lat
            }
        ).catch((err) -> null)
    ]).then((results) ->
        # get one object
        infos = _.filter results, (result) -> result?
        info = infos[_.random(0, _.size(infos) - 1)] if _.size(infos) > 0

        # report if no info
        console.error('no valid ip information for ' + ip) unless info

        # default
        unless info and info.country isnt 'XX'
            info =
                country: 'DE'
                ip: ip

        # valid currency and country
        info.country = 'DE' unless info.country and _.size(info.country) is 2

        # return
        info
    )
