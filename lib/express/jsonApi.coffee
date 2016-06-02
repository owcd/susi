_ = require 'lodash'
deepmerge = require 'deepmerge'
Inflector = require 'inflected'
JSONAPISerializer = require('jsonapi-serializer').Serializer
JSONAPIDeserializer = require('jsonapi-serializer').Deserializer

# the exports
module.exports = (options = {}) ->
    # does the serialization
    _serialize = (orig) ->
        (obj, meta) ->
            # set content type
            @set 'Content-Type', 'application/vnd.api+json'

            # whenever object is defined
            if obj? and (not _.isArray(obj) or _.size(obj) > 0)
                # prepare the object
                [data, definition, type] = _prepare obj

                # add type for attribute function
                definition.typeForAttribute = (attribute, data) ->
                    if data?._type?
                        Inflector.pluralize(data._type)
                    else
                        Inflector.pluralize(attribute)

                # create serializer
                serializer = new JSONAPISerializer(type, _.extend(definition,
                    keyForAttribute: options.serializer?.keyForAttribute or 'camelCase'
                ))

                # serialize data
                obj = serializer.serialize data

                # de-duplicate includes
                if obj.included?
                    obj.included = _.filter obj.included, (include) ->
                        include.type isnt Inflector.pluralize(type)
            else if obj? or meta?
                # wrap with data
                obj =
                    data: if _.isArray(obj) then [] else null

                # add meta info
                obj.meta = meta if meta?
            else
                @statusCode = 204

            # add api signature
            obj = _.extend(
                jsonapi:
                    version: "1.0"
            , obj) if obj?

            # pass through orginal function
            orig obj

    # deserialize the body
    _deserialize = (body) ->
        # init the definitions
        definition = {}

        # enrich the object with ids from its relationships
        if options.models? and body?.data?.type? and body.data.relationships?
            # model
            modelName = Inflector.camelize(Inflector.singularize(body.data.type))
            if options.models[modelName]?
                model = options.models[modelName]
                _.each body.data.relationships, (relationship, key) ->
                    # no association
                    return unless model.associations[key]?
                    association = model.associations[key]

                    # maybe there are no attributes yet
                    body.data.attributes = {} unless body.data.attributes?

                    # switch by type of association
                    identifier = null
                    if association.isSingleAssociation
                        identifier = association.identifier
                    else
                        identifier = association.associationAccessor

                    # any data in relationship?
                    data = relationship.data
                    if data?
                        # relationship data
                        isSingle = not _.isArray(data)
                        data = [data] if isSingle

                        # assign data
                        data = _.map data, (obj) ->
                            obj.id

                        # single?
                        data = _.first data if isSingle

                    # assign
                    body.data.attributes[identifier] = data

        # loop relationships
        if body?.data?.relationships?
            _.each body.data.relationships, (relationship, key) ->
                if relationship.data? and (not _.isArray(relationship.data) or _.size(relationship.data) > 0)
                    data = relationship.data
                    data = _.first(data) if _.isArray data
                    definition[data.type] =
                        valueForRelationship: _valueForRelationship

        # create deserializer
        _deserializer = new JSONAPIDeserializer(_.extend(definition,
            keyForAttribute: options.deserializer?.keyForAttribute or 'underscore_case'
        ))

        # deserialize
        _deserializer.deserialize(body)

    # return the middleware
    middleware = (req, res, next) ->
        # patch the json response
        if not res.__isJsonApiMasked
            res.__json = res.json
            res.json = _serialize(res.json.bind(res))
            res.__isJsonApiMasked = true

        # decode the body
        if req.body?.data?
            _deserialize(req.body).then((body) ->
                req.body = body
                next()
            )
        else
            # proceed
            next()

    # error handling part
    middleware.error = (err, req, res, next) ->
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
        res.__json
            jsonapi:
                version: "1.0"
            errors: errors

    # return
    middleware

# default value for relationship
_valueForRelationship = (relationship, included) ->
    if included?
        included
    else
        {id: relationship.id}

# prepare the object for serialization
_prepare = (obj, included = {}) ->
    # remember the result structure
    type = null
    isSingle = not _.isArray obj
    obj = [obj] if isSingle

    # prepare definition
    definition =  {}

    # map object to data
    data = _.map obj, (element) ->
        # convert to plain element
        plain = element
        if plain.toJSONApi?
            plain = plain.toJSONApi()
        else if plain.toJSON?
            plain = plain.toJSON()

        # shallow clone to avoid side effects
        plain = _.clone plain

        # is it a model?
        primary = 'id'
        if element.Model?
            # the type
            primary = element.Model.primaryKeyField
            type = element.Model.name.toLowerCase()
        else
            # key and type
            primary = element.jsonApiPrimaryKey or primary
            type = element.jsonApiType

        # object attributes
        attributes = _.without(_.keys(plain), primary)
        plain._type = type

        # circular reference?
        included[type] = {} unless included[type]?
        if included[type][plain[primary]]?
            plain = included[type][plain[primary]]
        else
            included[type][plain[primary]] = plain

            # is it a model
            if element.Model?
                # loop associations
                _.each element.Model.associations, (association, key) =>
                    # remove identifier from our attributes
                    if association.isSingleAssociation
                        attributes = _.without(attributes, association.identifierField)

                    # known value?
                    if element[key]?
                        # prepare association
                        [plain[key], assocDefinition, assocType] = _prepare element[key], included

                        # set reference
                        if association.isMultiAssociation
                            assocDefinition.ref = association.target.primaryKeyField
                        else
                            assocDefinition.ref = association.targetIdentifier

                        # add the association type to the map
                        plain[key]._type = assocType

                        # add or expand definition
                        if definition[key]?
                            definition[key] = deepmerge definition[key], assocDefinition
                        else
                            definition[key] = assocDefinition

                        # push the key
                        attributes.push key
                    else if association.foreignKey? and element[association.foreignKey]?
                        plain[key] = {}
                        plain[key][association.targetKey] = element[association.foreignKey]
                        definition[key] =
                            ref: association.targetKey
                            attributes: []

                        # add to map
                        plain[key]._type = association.target.name.toLowerCase()
                        attributes.push key

            # unionize attributes
            if definition.attributes?
                definition.attributes = _.union definition.attributes, attributes
            else
                definition.attributes = attributes

        # result
        plain

    # singlize
    data = _.first data if isSingle

    # return
    [data, definition, type]
