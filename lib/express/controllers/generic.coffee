_ = require 'lodash'
rqf = require 'rqf'
util = require 'util'
Promise = require 'bluebird'

# export depends on model
module.exports = (Model) ->
    # find
    find: (req, res, next) ->
        # the query
        query = req.query

        # id parameter?
        isSingle = false
        if req.params?.id?
            query.filter = {} unless query.filter?
            query.filter.id = req.params.id
            isSingle = true

        Model.findByParameters(req.context, query).then((entities) ->
            entities = _.first(entities) if isSingle
            res.json entities
        ).catch((err) ->
            next err
        )

    # create
    create: (req, res, next) ->
        Model.create(req.body).then((entity) ->
            res.json entity
        ).catch((err) ->
            next err
        )

    # update
    update: (req, res, next) ->
        Model.findById(req.params.id).then((entity) ->
            throw new Error 'entity not found' unless entity?
            entity.update req.body
        ).then((entity) ->
            res.json entity
        ).catch((err) ->
            next err
        )

    # remove
    remove: (req, res, next) ->
        Model.findById(req.params.id).then((entity) ->
            throw new Error 'entity not found' unless entity?
            entity.destroy()
        ).then( ->
            res.json null
        ).catch((err) ->
            next err
        )