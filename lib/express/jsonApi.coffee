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
            else
                # wrap with data
                obj =
                    data: if _.isArray(obj) then [] else null

                # add meta info
                obj.meta = meta if meta?

            # add api signature
            obj = _.extend(
                jsonapi:
                    version: "1.0"
            , obj)

            # pass through orginal function
            orig obj

    # initialize the deserializer
    _deserializer = new JSONAPIDeserializer(
        keyForAttribute: options.deserializer?.keyForAttribute or 'underscore_case'
    )

    # return the middleware
    (req, res, next) ->
        # patch the json response
        if not res.__isJsonApiMasked
            res.json = _serialize(res.json.bind(res))
            res.__isJsonApiMasked = true

        # decode the body
        if req.body?.data?
            req.body = _deserializer.deserialize req.body

        # proceed
        next()

# prepare the object for serialization
_prepare = (obj, included = {}) ->
    # remember the result structure
    type = null
    isSingle = not _.isArray obj
    obj = [obj] if isSingle

    # prepare definition
    map = {}
    definition =
        typeForAttribute: (attribute) ->
            if map[attribute]?
                Inflector.pluralize(map[attribute])
            else
                Inflector.pluralize(attribute)

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
                        map[key] = assocType

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
                        map[key] = association.target.name.toLowerCase()
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