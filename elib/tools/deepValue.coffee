module.exports = (obj, path, def) ->
    # define path
    path = path or ''

    # loop splitted path
    for p in path.split '.'
        return def if not obj or typeof obj isnt 'object'
        obj = obj[p]

    # default?
    obj = def unless obj?

    # return
    obj