_ = require 'underscore'

# find the element in the included array
module.exports.find = find = (arr, type, id) ->
    _.find arr, (element) ->
        element.type is type and element.id is id

# filter the array for the given type
module.exports.filter = filter = (arr, type) ->
    _.filter arr, (element) ->
        element.type is type

#turns {id: id, type: 'type', attributes: {}} into plain object with id and attrs. works for arrays too.
module.exports.flatten = flatten = (data, included = null) ->
    # exclude null objects
    return null unless data?

    # single object or array?
    isArray = _.isArray data
    data = [data] unless isArray

    # map the data
    data = data.map (obj) ->
        # init the transformed object
        transformed = _.extend
            id: obj.id
        , obj.attributes

        if obj.relationships?
            transformed = _.extend transformed, _.mapObject(obj.relationships, (value) ->
                # no data in relationship
                return null unless value?.data?

                # single relationsship
                isSingle = not _.isArray value.data
                value.data = [value.data] if isSingle

                # map the relationship
                value.data = value.data.map (rel) ->
                    related = null
                    related = find included, rel.type, rel.id if included?
                    if related?
                        flatten related, included
                    else
                        {id: rel.id}

                # return
                value.data = _.first(value.data) if isSingle
                value.data
            )

        # return
        transformed

    # return
    data = _.first data unless isArray
    data


# create an jsonApi body using type id and data
module.exports.body = (type, attributes) ->
    # is an array?
    isArray = _.isArray attributes
    attributes = [attributes] unless isArray

    # init
    results = []

    # loop attributes
    for attribute in attributes
        # init result
        result =
            type: type

        # move relationships
        if attribute.relationships?
            result.relationships = attribute.relationships
            delete attribute.relationships

        # add id?
        if _.isObject attribute
            if attribute.id?
                result.id = attribute.id
                delete attribute.id
            result.attributes = attribute
        else
            result.id = attribute

        # add to results
        results.push result

    # return
    {
        data: if isArray then results else _.first(results)
    }

# builds relationship body
module.exports.relationship = (type, ids) ->
    # is an array?
    isArray = _.isArray ids
    ids = [ids] unless isArray

    # init
    results = []

    # loop id
    for id in ids
        results.push
            type: type
            id: id

    # return
    {
        data: if isArray then results else _.first(results)
    }