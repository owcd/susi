_ = require 'underscore'

# exports the deep clone
module.exports = deepClone = (object) ->
    JSON.parse(JSON.stringify(object)) if object?
