_ = require 'underscore'
_s = require 'underscore.string'
res = require('express').response

deepExtend = require 'elib/tools/deepExtend'

module.exports = (options = {}) ->
    # init options
    options.relations ?= {}
    options.mappings ?= {}

    # initialize hashids
    hashids = require('elib/tools/hashids')(options)

    addResourceRelationship = (resource, reference, type, id, isArray) ->
        # make sure relationships is there
        resource.relationships ?= {}

        # the relationship value
        value =
            type: type
            id: id
        value = null unless id?

        # is it an array?
        if isArray
            resource.relationships[reference] ?=
                data: []
            resource.relationships[reference].data.push value
        else
            resource.relationships[reference] =
                data: value

    parseIncluded = (resource, reference, includedResource, includeType, included, isArray) ->
        # really a resource or only an id?
        if _.isObject includedResource
            # call our parseResource again to make sure we are parsing all the included resources
            result = parseResourceRecursive includedResource, includeType, included
            if included[includeType]? and Array.isArray(included[includeType])
                included[includeType].push result
            else
                included[includeType] = [result]

            # parse links
            addResourceRelationship resource, reference, result.type, result.id, isArray
        else
            addResourceRelationship resource, reference, includeType, hashids.hash(includedResource, includeType), isArray

    parseResourceRecursive = (resource, type, included, aggregated = false) ->
        result =
            id: null
            type: type
            attributes: {}
        relations = options.relations[type] if options.relations[type]?
        for key, value of resource
            # defined relation?
            if relations?[key]?
                # fetch relation type
                relationType = if _.isObject(relations[key]) then relations[key]['type'] else relations[key]

                # if the value is an array, we want to parse all of its elements
                if _.isArray(value)
                    for item in value
                        parseIncluded result, key, item, relationType, included, true
                else
                    parseIncluded result, key, value, relationType, included, false
            else if key is 'id' # hash type key?
                result[key] = hashids.hash value, type
                result[key] = '-' + result[key] + '-' if aggregated
            else if _s.endsWith(key, '_id') and resource["#{key[...-3]}_type"]
                # generic type based mapping (e.g. remote_id / remote_type)
                relationType = _.findKey options.mappings, (item) ->
                    item is resource["#{key[...-3]}_type"] + '_id'

                # generic link found
                if relationType?
                    result.attributes[key] = hashids.hash value, relationType
                else
                    result.attributes[key] = value
            else
                # figure out link type
                relationType = _.findKey options.mappings, (item) ->
                    item is key

                # figure out relations type
                relationName = _.findKey relations, (item) ->
                    if _.isObject item
                        item.mapping is key
                    else if _.has options.mappings, item
                        options.mappings[item] is key
                    else
                        false

                # relationName found but no linkType
                if relationName? and not relationType?
                    relationType = if _.isObject(relations[relationName]) then relations[relationName]['type'] else relations[relationName]

                # both link and relation type found?
                if relationType? and relationName?
                    # hashed value
                    hashed = hashids.hash value, relationType

                    # add resource link
                    result.attributes[key] = hashed

                    # add resource link
                    hashed = null if value is 0
                    addResourceRelationship result, relationName, relationType, hashed, false
                else if relationType?
                    result.attributes[key] = hashids.hash value, relationType
                else
                    result.attributes[key] = value

        # return the new resource
        delete result.attributes unless _.size(result.attributes) > 0
        result

    deduplicateIncluded = (included) ->
        # this basically makes sure we are not sending the same included element twice
        deduplicated = []
        for key, values of included
            ids = {}
            for value in values
                if value.id not of ids
                    ids[value.id] = value
                else
                    ids[value.id] = deepExtend ids[value.id], value
            deduplicated = deduplicated.concat _.values(ids)
            ###
                The logic below is ready to be used, what's left is a confirmation
                if it's needed or not, what it basically does is that it makes sure
                the included elements are at least sorted by the first entry in the sorts
                jsonApiAttribute of a type.
                The included elements might be elements gathered by sub-queries which means the ORDER BY query
                didn't cover all of them but only parts them.
            ###
            # # since included are deduplicated now, let's check if we need to sort
            # # this included array
            # if jsonApiAttributes[key]?.sorts?.length > 0 and deduplicatedLinked[key].length > 1
            #     sorts = jsonApiAttributes[key].sorts
            #     # since we cannot handle combined sorts at this point
            #     # we will be only sorting on the first element in the sort array
            #     deduplicatedLinked[key] = _.sortBy deduplicatedLinked[key], (o) -> o[sorts[0][0]]
            #     # we still need to check if the sort is descending then we need to reverse the array
            #     if sorts[0][1] is 'DESC'
            #         deduplicatedLinked[key].reverse()
        deduplicated

    parseResources = (resources, type) ->
        # is it an array?
        result =
            data: null
            included: {}

        if Array.isArray(resources)
            # loop resources
            result.data = []
            for resource in resources
                aggregated = resource?.aggregated? and resource.aggregated
                resource = resourceToJson resource
                result.data.push parseResourceRecursive(resource, type, result.included, aggregated)
        else if resources is null #individualResource special case
            result.data = null
        else
            aggregated = resource?.aggregated? and resource.aggregated
            resources = resourceToJson resources
            result.data = parseResourceRecursive resources, type, result.included, aggregated

        # finalize included
        if _.size(result.included) > 0
            result.included = deduplicateIncluded result.included
        else
            delete result.included

        # return
        result

    resourceToJson = (resource) ->
        if resource.getPlain?
            resource.getPlain()
        else if resource.toJSON?
            resource.toJSON()
        else
            JSON.parse JSON.stringify resource

    # register and return send method
    res.jsonApiSend = res.limeSend = (resources, meta) ->

        unless resources
            @statusCode = 204
            @send()
        else
            # http://jsonapi.org/format/#fetching-resources-responses-200
            # A server MUST respond to a successful request to fetch an individual resource with a resource object
            # or null provided as the response document's primary data.
            individualResource = @req.jsonApiAttributes[@req.jsonApiAttributes.type]?.individualResource
            if individualResource
                resources =
                    switch resources.length
                        when 0 then null
                        when 1 then resources[0]
                        else resources

            @set 'Content-Type', 'application/vnd.api+json'
            meta = if meta? then {meta: meta} else {}
            @send _.extend(
                jsonapi:
                    version: "1.0"
            , parseResources(resources, @req.jsonApiAttributes.type), meta)
