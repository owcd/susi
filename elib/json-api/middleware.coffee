_ = require 'underscore'
_s = require 'underscore.string'
error = require 'elib/error'
jsonApi = require 'elib/tools/jsonApi'

# module export
module.exports = (options = {}) ->
    # init options
    options.relations ?= {}
    options.mappings ?= {}
    options.typeIndex ?= 1

    getValues = (value, mapFunction) ->
        # this is only to parse the values
        # and if supplied a mapFunction
        # we should apply it to the results
        result = value
        result = result?.split(',').map(decodeURIComponent) unless _.isArray(result)
        result = result.map(mapFunction) if mapFunction and result
        result

    parseAttribute = (attr, mainType, mapFunction) ->
        return unless attr
        result = {}
        if _.isArray attr
            result = _.extend result, parseAttribute(item, mainType, mapFunction) for item in attr
        else if _.isObject attr
            for key, val of attr
                if val is true
                    result = _.extend result, parseAttribute(key, mainType, mapFunction)
                else
                    result[key] = getValues(val, mapFunction)
        else
            result[mainType] = getValues attr, mapFunction
        result

    appendOption = (mainOptions, parsedOption, fieldName) ->
        for type, value of parsedOption
            mainOptions[type] = {} unless mainOptions[type]
            mainOptions[type][fieldName] = value

    appendFilters = (queryOptions, type, filters) ->
        queryOptions[type] = {} unless queryOptions[type]
        queryOptions[type].filters = {} unless queryOptions[type].filters

        for key, value of filters
            #create 'contains in' filter
            if _.isArray value
                queryOptions[type].filters[key] =
                    in: value
                delete filters[key]
            #break the filters by type
            else if _.isObject value
                # map >, >=, <, <=
                _.each _.keys(value), (k) ->
                    return unless k in ['gt', 'gte', 'lt', 'lte']
                    queryOptions[type].filters[key] = {} unless queryOptions[type].filters[key]?
                    queryOptions[type].filters[key]['$' + k] = value[k]
                    delete value[k]

                # append filters if not empty value
                appendFilters queryOptions, key, value unless _.isEmpty value
                delete filters[key]
        queryOptions[type].filters = _.extend queryOptions[type].filters, filters

    # exported methods
    parseAttributes: (req, res, next) ->
        # we might be able to figure out the type only if
        # the route is defined and passed to the express router
        type = req.route?.split('/')[options.typeIndex]

        sorts = parseAttribute req.query.sort, type, (sort) ->
            if _s.startsWith sort, '-'
                # then this is desc
                [sort[1..], 'DESC']
            else
                [sort, 'ASC']

        queryOptions = {}
        # parse all the request options
        appendOption queryOptions, parseAttribute(req.query.fields, type), 'fields'
        appendOption queryOptions, parseAttribute(req.query.include, type), 'includes'
        appendOption queryOptions, parseAttribute(req.query.templates, type), 'templates'
        appendOption queryOptions, parseAttribute(req.query.limit, type), 'limit'
        appendOption queryOptions, parseAttribute(req.query.offset, type), 'offset'
        appendOption queryOptions, sorts, 'sorts'

        filters = _.clone req.query
        # after removing the parsed options we should only have the query left
        delete filters.fields
        delete filters.include
        delete filters.sort
        delete filters.templates
        delete filters.limit
        delete filters.offset

        filters = undefined if _.isEmpty filters

        appendFilters queryOptions, type, filters if filters?

        # new limeApi
        req.limeApi = _.clone queryOptions
        req.limeApi.type = type

        # old jsonApiAttributes
        queryOptions.user = req.user if req.user
        queryOptions.institution_id = req.institution_id
        req.jsonApiAttributes = queryOptions
        req.jsonApiAttributes.type = type

        next()

    # Exported methods
    parseBody: (req, res, next) ->
        # lime api unavailable?
        throw new Error('please parse attributes before body') unless req.limeApi?

        # body?
        if req.body?
            # data attribute?
            if req.body.data?
                # get data
                data = req.body.data
                isArray = _.isArray data

                # wrap
                data = [data] unless isArray
                elements = []

                # loop
                for element in data
                    # verify type - impossible right now because of resource-less api style
                    #throw new error.InvalidArgument("body data type #{element.type} differs from api type #{req.limeApi.type}") unless element.type is req.limeApi.type

                    # set body
                    el = element.attributes or {}
                    if element.id?
                        el.id = element.id
                    else
                        delete el.id if el.id?

                    # resolve (and remove) relationships
                    if element.relationships?
                        # get relations
                        relations = options.relations[element.type] or {}

                        # loop relationships
                        for key, value of element.relationships
                            # is it specified?
                            if relations[key]?
                                relationType = relations[key]
                                if _.isObject relationType
                                    mapping = relationType.mapping
                                    relationType = relationType.type
                                else
                                    mapping = options.mappings[relationType]

                                # verify mapping
                                #throw new error.InvalidArgument("relationship of type #{relationType} differs from #{value.data.type} for #{key}") unless relationType is value.data.type

                                # array or not
                                if not value.data?
                                    el[mapping] = null
                                else if _.isArray value.data
                                    el[mapping] = _.map value.data, (d) ->
                                        d.id
                                else
                                    # store mapping
                                    if value.data #seems that ember-data does not omit empty reltion, but passes it as null
                                        el[mapping] = value.data.id

                    # only an id?
                    el = el.id if _.size(el) is 1 and el.id?

                    # push
                    elements.push el

                # unwrap and set
                elements = _.first(elements) unless isArray
                req.limeApi.body = elements
            else
                # fallback to traditional body
                req.limeApi.body = req.body

        # proceed
        next()

    parseIds: (req, res, next, reqIds, paramName) ->
        type = req.route?.path?.split('/')[1]

        req.jsonApiAttributes[type] = req.jsonApiAttributes[type] or {}
        req.limeApi[type] = req.limeApi[type] or {}

        # here we will get the ids from the req.params because probably the hashids
        # middleware has hashed the ids and put them there
        ids = req.params[paramName]
        if not _.isArray(ids)
            ids = [ids]

            # http://jsonapi.org/format/#fetching-resources-responses-200
            # A server MUST respond to a successful request to fetch an individual resource with a resource object
            # or null provided as the response document's primary data.
            req.jsonApiAttributes[type].individualResource = true

        if req.jsonApiAttributes[type].filters
            req.jsonApiAttributes[type].filters.id = in: ids
        else
            req.jsonApiAttributes[type].filters =
                id:
                    in: ids

        if req.limeApi[type].filters
            req.limeApi[type].filters.id = in: ids
        else
            req.limeApi[type].filters =
                id:
                    in: ids
        next()

    errors: (err, req, res, next) ->
        # initialize
        httpCode = 500
        errors = []

        # wrap in array
        err = [err] unless _.isArray(err)

        # loop errors
        for error, key in err
            # init error with code
            code = 500
            title = 'Internal server error'

            # error name given?
            if error.name?
                if error.name is 'PermissionDenied'
                    code = 403
                    title = 'This operation is forbidden'
                else if error.name is 'Unauthorized'
                    code = 401
                    title = 'Please authorize yourself'
                else if error.name is 'ObjectNotFound'
                    code = 404
                    title = 'Not Found'
                else if error.name is 'SequelizeUniqueConstraintError'
                    code = 409
                    title = 'Conflict'
                else if error.name in ['InvalidState', 'InvalidArgument']
                    code = 400
                    title = 'Bad Request'
                else if error.name is 'NoContent'
                    code = 204
                    title = 'No Content'
                else if error.name is 'NotImplemented'
                    code = 501
                    title = 'This is not implemented yet'
                    # cleaning up the OAuth2Errors
                else if error.name is 'OAuth2Error' and error.error is 'invalid_request'
                    code = 401
                    title = 'Please authorize yourself'
                else if error.name is 'OAuth2Error' and error.error is 'wrong_credentials'
                    code = 401

            # set title
            title = error.message if error.message? and error.message isnt ''

            # error details given
            details = {}
            if error.details?
                details = _.pick error.details, ['id', 'title', 'detail', 'status', 'source', 'meta']

            # push error
            errors.push _.extend
                title: title
                status: code
            , details

            # set httpCode
            httpCode = code if key is 0

        # send response
        res.set 'Content-Type', 'application/vnd.api+json'
        res.statusCode = httpCode
        res.send
            jsonapi:
                version: "1.0"
            errors: errors
