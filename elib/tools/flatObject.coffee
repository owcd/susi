_ = require 'underscore'

# hydrates a flattened object from array
module.exports.hydrate = hydrate = (items) ->
    # loop objects
    obj = {}
    for path, value of items
        path = path.split('.')
        leaf = path.pop()
        current = obj
        for name in path
            current[name] = {} unless current[name]? and _.isObject(current[name])
            current = current[name]
        current[leaf] = value
    obj

# flattens an object into an array
module.exports.reduce = reduce = (object, path = null) ->
    obj = {}
    for key, value of object
        name = key
        name = [path, key].join('.') if path?
        if _.isObject(value) and not _.isArray(value)
            obj = _.extend obj, reduce(value, name)
        else
            obj[name] = value
    obj
