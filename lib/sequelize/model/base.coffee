_ = require 'lodash'
rqf = require 'rqf'
Promise = require 'bluebird'
Skeleton = require './skeleton'

module.exports = class Base
    # create the find options from parameters
    @_createFindOptionsByParameters: (context, parameters) ->
        # initialize
        options = {}
        skeleton = @skeleton()

        # add filter
        if parameters?.filter?
            options.where = _.pick parameters.filter, skeleton.filters

        # add fields
        if parameters?.fields?
            fields = parameters.fields
            fields = fields.split(',') unless _.isArray(fields)
            options.attributes = _.intersection fields, skeleton.fields
        else
            options.attributes = skeleton.fields

        # make sure required fields are included
        options.attributes = _.union skeleton.requiredFields, options.attributes

        # add sort
        if parameters?.sort?
            sort = parameters.sort
            sort = sort.split(',') unless _.isArray(sort)
            options.order = []
            _.each sort, (field) ->
                # field and order
                ordering = 'ASC'
                if _.startsWith(field, '-')
                    field = field.substring 1
                    ordering = 'DESC'

                # allowed?
                return unless _.includes skeleton.sort, field

                # add
                options.order.push [field, ordering]
        else
            options.order = [[@primaryKeyAttribute, 'ASC']]

        # add offset
        if parameters?.offset?
            options.offset = parameters.offset

        # add limit
        if parameters?.limit?
            options.limit = Math.min(parseInt(parameters.limit), skeleton.limit)
        else
            options.limit = skeleton.limit

        # add includes
        if parameters?.include?
            include = parameters.include
            include = include.split(',') unless _.isArray(include)
            _.each include, (related) =>
                # look for relationship
                return unless @associations[related]?
                association = @associations[related]

                # only include single associations
                return unless association.isSingleAssociation

                # build target model options
                targetModelOptions = {}
                if parameters[related]?
                    targetModelOptions = association.target._createFindOptionsByParameters context, parameters[related]
                    targetModelOptions = _.pick targetModelOptions, ['attributes', 'where']

                # add fixed parameters
                targetModelOptions.model = association.target
                targetModelOptions.as = related
                targetModelOptions.required = false

                # push to include array
                options.include = [] unless options.include?
                options.include.push targetModelOptions

        #console.log 'options', options

        # return the options
        options

    # find by parameters
    @findByParameters: (context, parameters) ->
        @findAll(@_createFindOptionsByParameters(context, parameters)).then((entities) =>
            if parameters?.include?
                include = parameters.include
                include = include.split(',') unless _.isArray(include)
                Promise.map(include, (related) =>
                    # look for relationship
                    return unless @associations[related]?
                    association = @associations[related]

                    # only include multi associations
                    return unless association.isMultiAssociation

                    # build target model parameters
                    targetModelParameters = {}
                    targetModelParameters = parameters[related] if parameters[related]?

                    # add filter
                    targetModelParameters.filter = {} unless targetModelParameters.filter?
                    targetModelParameters.filter[association.identifierField] = _.uniq(_.map(entities, (entity) ->
                        entity[association.source.primaryKeyField]
                    ))

                    # find by paramters on target
                    association.target.findByParameters(context, targetModelParameters).then((relatedEntities) ->
                        _.each entities, (entity) ->
                            entity[related] = _.filter relatedEntities, (relatedEntity) ->
                                relatedEntity[association.identifierField] is entity[association.source.primaryKeyField]
                    )
                ).then( ->
                    entities
                )
            else
                entities
        )

    # associate function to override
    @associate: (models) ->

    # the models skeleton
    @skeleton: ->
        new Skeleton @

    # do the definition
    @define: (sequelize) ->
        # define options
        options = @options or {}
        options.tableName = @tableName if @tableName?
        options.timestamps = true unless options.timestamps?
        options.underscored = true unless options.underscored?

        # define instance methods
        instanceMethods = {}
        for key, func of @prototype when key isnt 'constructor'
            instanceMethods[key] = func
        options.instanceMethods = instanceMethods

        # define class methods
        classMethods = {}
        for key, func of @ when typeof(func) is 'function'
            classMethods[key] = func
        options.classMethods = classMethods

        # define the model
        model = sequelize.define(@name, @fields, options)

        # register constants
        if @constants?
            for k, v of @constants
                model[k] = v

        # return
        model

return
seqLib = rqf('lib/sequelize')
DataTypes = seqLib.DataTypes
sequelize = seqLib.sequelize

class Main
    @findById: (id) ->
        @find id

    getPlain: (template = null) ->
        plain = @toJSON()
        queryParameters = @Model.options.queryParameters
        if queryParameters?
            _.each queryParameters.fields.additional, (field) =>
                if @dataValues[field]?
                    plain[field] = @dataValues[field]
                else if @[field]?
                    plain[field] = @[field]

            _.each queryParameters.includes, (include) =>
                if @[include] and _.isArray(@[include])
                    plain[include] = []
                    _.each @[include], (includeObj) ->
                        if _.isFunction includeObj.getPlain
                            plain[include].push(includeObj.getPlain(template))
                        else
                            plain[include].push includeObj
                else if @[include]
                    if _.isFunction @[include].getPlain
                        plain[include] = @[include].getPlain(template)
                    else
                        plain[include] = @[include]

            # filter by template
            if template? and queryParameters.templates[template]?.fields?
                plain = _.pick plain, queryParameters.templates[template].fields
        plain
    
    @sequelizeModel = ->
        return sequelize.importCache[@name] if sequelize.importCache[@name]?

        # define options
        options = @options
        unless options?
            options =
                tableName: @tableName
        
        instanceMethods = {}
        for key, fun of @prototype when key isnt 'constructor'
            instanceMethods[key] = fun
        options.instanceMethods = instanceMethods
        
        hooksToAdd = ['beforeValidate', 'afterValidate', 'beforeCreate', 'afterCreate', 'beforeDestroy'
            , 'afterDestroy', 'beforeUpdate', 'afterUpdate', 'beforeBulkCreate', 'afterBulkCreate'
            , 'beforeBulkDestroy', 'afterBulkDestroy', 'beforeBulkUpdate', 'afterBulkUpdate', 'beforeFind'
            , 'beforeFindAfterExpandIncludeAll', 'beforeFindAfterOptions', 'afterFind', 'beforeDefine'
            , 'afterDefine', 'beforeInit', 'afterInit', 'beforeDelete', 'afterDelete', 'beforeBulkDelete'
            , 'afterBulkDelete'
        ]
        hooks = {}
        for key, fun of @ when typeof(fun) is 'function' and key in hooksToAdd
            hooks[key] = fun
        options.hooks = hooks unless _.isEmpty(hooks)
        hooksToAdd.push 'sequelizeModel'

        classMethods = {}
        for key, fun of @ when typeof(fun) is 'function' and key not in hooksToAdd
            classMethods[key] = fun
        options.classMethods = classMethods

        fieldsToAdd = ['queryParameters']
        for fieldToAdd in fieldsToAdd
            if @[fieldToAdd]?
                if @["_#{fieldToAdd}"]?
                    options[fieldToAdd] = _.extend(@["_#{fieldToAdd}"], @[fieldToAdd])
                else
                    options[fieldToAdd] = @[fieldToAdd]
            else if @["_#{fieldToAdd}"]?
                options[fieldToAdd] = @["_#{fieldToAdd}"]

        # define and cache model
        model = sequelize.importCache[@name] = sequelize.define(@name, @fields, options)

        # register constants
        if @constants?
            for k, v of @constants
                model[k] = v

        # return
        model

module.exports = Main