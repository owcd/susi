# require
Promise = require 'bluebird'

# export
module.exports = promiseWhile = (predicate, action, value) ->
    Promise.resolve(value).then(predicate).then((condition) ->
        promiseWhile(predicate, action, action()) if condition
    )
