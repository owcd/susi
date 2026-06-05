deepClone = require 'elib/tools/deepClone'
deepExtend = require 'elib/tools/deepExtend'

# export deepExtend
module.exports = (destination, sources...) ->
    for source in sources
        destination = deepExtend deepClone(destination), deepClone(source)
    destination
