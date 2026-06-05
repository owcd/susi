_ = require 'underscore'

# exports the deep extend
module.exports = generateCode = (length, type) ->
    # define length
    length = 6 unless length?

    # alphabeth
    ints = '23456789'
    uppers = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    lowers = 'abcdefghijklmnpqrstuvwxyz'

    # chars
    chars = ''

    # by type
    start = 2
    switch type
        when 'int'
            chars += ints
            start = 1
        when 'lower'
            chars += lowers
            chars += ints
        when 'upper'
            chars += uppers
            chars += ints
        else
            chars += uppers
            chars += lowers
            chars += ints

    # code
    code = (chars.charAt(_.random(0, chars.length - 1)) for i in [start..length])
    
    # Makes sure the code starts with a character (prevents misinterpretation
    code.unshift(chars.charAt(_.random(0, chars.length - ints.length))) unless type is 'int'

    # return final code
    code.join('')
