Function::property = (prop, desc) ->
    Object.defineProperty @prototype, prop, desc

# modules
_ = require 'underscore'
_s = require 'underscore.string'
fs = require 'fs'
path = require 'path'
stripJsonComments = require 'strip-json-comments'

# deep extending
deepExtend = require 'elib/tools/deepExtend'

# exports class
module.exports = class Configuration

    # load configuration
    load: (dir) ->
        # read available file
        config = {}
        _.each fs.readdirSync(dir), (file) =>
            if _s.endsWith file, 'json'
                # extract name
                parts = file.split '.'
                name = parts.shift()
                flavor = parts.shift()
                flavor = 'override' if flavor isnt 'default'

                # try to load content
                try
                # load the content
                    content = fs.readFileSync path.join(dir, file), 'utf8'
                    content = stripJsonComments content

                    # set config
                    config[name] = {} unless _.has config, name

                    # parse data
                    config[name][flavor] = JSON.parse content
                catch e
                    console.error 'Unable to load configuration ' + file
                    console.error e

        # loop namespaces
        _.each config, (values, namespace) =>
            if _.has values, 'default'
                if _.has values, 'override'
                    @[namespace] = deepExtend values.default, values.override
                else
                    @[namespace] = values.default
            else
                @[namespace] = values.override

        # merge default namespace
        if _.has @, 'default'
            _.each @['default'], (value, key) =>
                @[key] = value
            delete @['default']
