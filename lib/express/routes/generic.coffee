_ = require 'lodash'
Inflector = require 'inflected'
Controller = require '../controllers/generic'

module.exports = (app, models) ->
    # loop models
    _.each models, (model, key) ->
        # ignore sequelize keys
        return if key in ['sequelize', 'Sequelize']

        # which methods?
        methods = model.skeleton().api
        methods = ['find', 'create', 'update', 'remove'] if methods is 'all'

        # name
        name = Inflector.pluralize(key).toLowerCase()

        # the controller
        controller = Controller model

        # loop methods
        _.each methods, (method) ->
            if method is 'find'
                app.get "/#{name}", controller[method]
                app.get "/#{name}/:id", controller[method]
            else if method is 'create'
                app.post "/#{name}", controller[method]
            else if method is 'update'
                app.patch "/#{name}/:id", controller[method]
            else if method is 'remove'
                app.delete "/#{name}/:id", controller[method]

