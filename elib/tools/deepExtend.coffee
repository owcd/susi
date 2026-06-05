_ = require 'underscore'

# deep extend two objects
deepExtend = (destination, source) ->
    if _.isObject source
        _.each source, (value, property) =>
            if _.has destination, property
                if _.isObject(value) and _.isObject(destination[property])
                    destination[property] = deepExtend destination[property], value
                else
                    destination[property] = value
            else
                destination[property] = value

        # return
        destination
    else
        source

# export deepExtend
module.exports = (destination, sources...) ->
    for source in sources
        destination = deepExtend destination, source if source?
    destination
