module.exports = (s) ->
    s.split('').reduce(((a, b) ->
        a = (a << 5) - a + b.charCodeAt(0)
        a & a
    ), 0) & 0x0FFFFFFF