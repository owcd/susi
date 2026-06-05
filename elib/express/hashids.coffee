_ = require 'underscore'
_s = require 'underscore.string'

# module export
module.exports = (options = {}) ->
    # init options
    options.relations ?= {}
    options.mappings ?= {}

    # initialize hashids
    hashids = require('elib/tools/hashids')(options)

    decodeArr = (type, arr, decode) ->
        return arr if not arr or arr.length is 0

        newArr = []
        for obj in arr
            if _.isArray obj
                newArr.push decodeArr(type, obj)
            else if _.isObject obj
                newArr.push decodeObj(type, obj)
            else if _.isString(obj) and decode
                newArr.push hashids.decode(obj, type)
            else
                newArr.push obj
        newArr

    decodeHashedId = (id, type) ->
        # decode hashed id
        value = hashids.decode(id, type)

        # undecodable if input = output
        value = null if id is value

        # pass along values that are undecodable and are non-numeric
        # Notice: because isNaN returns false for strings like '84e684'
        # it may not pass along all the string values that are undecodable
        # shouldn't be a problem although
        value = id if not value? and isNaN(id)

        # decoded value
        value

    decodeObj = (type, obj) ->
        relations = options.relations[type] if options.relations[type]?

        # find our relation type
        findRelationType = (key) ->
            # basic mapping
            relationType = _.findKey options.mappings, (item) ->
                item is key

            # widen search to our type
            if relations? and not relationType?
                # figure out relations type
                relationKey = _.findKey relations, (item) ->
                    if item is key
                        true
                    else if _.isObject item
                        item.mapping is key
                    else if _.has options.mappings, item
                        options.mappings[item] is key
                    else
                        false

                # object
                if _.isObject relations[relationKey]
                    relations[relationKey].type
                else
                    relations[relationKey]
            else
                relationType

        # loop object properties
        for key, value of obj
            # switch by type of value
            if _.isArray value
                relationType = findRelationType key
                if relationType?
                    obj[key] = decodeArr relationType, value, true
                else
                    obj[key] = decodeArr type, value, key is 'id'
            else if _.isObject value
                # decode links object
                relationType = findRelationType key
                if relationType?
                    obj[key] = decodeObj relationType, value
                else
                    obj[key] = decodeObj type, value
            else if key is 'id'
                if obj.type?
                    obj[key] = decodeHashedId(value, obj.type)
                else
                    obj[key] = decodeHashedId(value, type)
            else if _s.endsWith(key, '_id') and obj["#{key[...-3]}_type"]
                # generic type based mapping (e.g. remote_id / remote_type)
                relationType = _.findKey options.mappings, (item) ->
                    item is obj["#{key[...-3]}_type"] + '_id'

                # generic link found
                if relationType?
                    obj[key] = decodeHashedId(value, relationType)
                else
                    obj[key] = value
            else if _.isString(value)
                relationType = findRelationType key
                obj[key] = decodeHashedId(value, relationType) if relationType?

        obj

    ###
        Exported methods
    ###
    paramDecode: (req, res, next, paramValue, paramName) ->
        # this will basically be called whenever a specified param is being identified
        # we will be ignoring the paramValue provided because we need the salt to figure
        # out how to decode the value

        # this type is only used if the param name is id or ids
        type = null
        if paramName in ['id', 'ids']
            type = req.route?.path?.split('/')[1]
        else
            # basic mapping
            type = _.findKey options.mappings, (item) ->
                item is paramName

        # decode?
        req.params[paramName] = decodeHashedId(paramValue, type) if type

        # proceed
        next()

    queryBodyDecode: (req, res, next) ->
        type = req.route?.split('/')[1]
        req.query = decodeObj type, req.query
        if req.body?
            req.body = if _.isArray(req.body) then decodeArr(type, req.body) else decodeObj(type, req.body)

        next()
