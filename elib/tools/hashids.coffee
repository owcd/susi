_ = require 'underscore'
Hashids = require 'hashids'

# main export
module.exports = (options) ->
    # salts
    salts = options?.salts or options or {}
    
    # Module Methods
    hash: (id, type) ->
        if type of salts and id
            encode id, salts[type]
        else
            id
    
    decode: (hashedId, type) ->
        if type of salts and hashedId and _.isString(hashedId)
            values = []
            for paramVal in hashedId.split(',')
                # do not change 6 to other value. It is hardcoded because it is used to create links. If value is changed, links will be broken
                value = paramVal
                if paramVal.length >= 6
                    value = decode paramVal, salts[type]
                    value = paramVal unless value?
                values.push value
    
            if values.length > 1
                values
            else
                values[0]
        else
            hashedId

# encode helper
module.exports.encode = encode = (id, salt) ->
    # id should always be a number
    id = Number id

    # alphabet and minhash length should never change
    hashids = new Hashids(salt, 6, 'abcdefghjklmnpqrstuvwxyz23456789')
    hashids.encode(id)

# decode helper
module.exports.decode = decode = (encodedId, salt) ->
    # alphabet and minhash length should never change
    hashids = new Hashids(salt, 6, 'abcdefghjklmnpqrstuvwxyz23456789')
    
    # hashids returns an array
    ids = hashids.decode(encodedId)

    # let's return the first element or undefined
    ids[0] if ids.length > 0
