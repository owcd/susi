# require
_s = require 'underscore.string'

module.exports.format = (value) ->
    _s.sprintf '%.2f', value

module.exports.formatAmount = (value) ->
    Number(_s.sprintf '%.2f', value)