
module.exports = (app) ->
    # Catch all route
    app.get '*', app.controllers.main.default