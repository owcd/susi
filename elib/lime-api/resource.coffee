# require
Promise = require 'bluebird'

# elib
error = require 'elib/error'

# defines the lime resource api
module.exports = (type, Model) ->
    retrieve: ->
        (req, res, next) ->
            # find by options
            Model.findByLime(req.context, req.limeApi).then((rows) ->
                # send rows
                res.limeSend rows

                # next
                next()
            ).catch((err) ->
                next err
            )

    create: ->
        (req, res, next) ->
            Promise.try( ->
                # no data
                throw new error.InvalidArgument('data is missing') unless req.limeApi.body?

                # remove id
                body = req.limeApi.body
                delete body.id if body.id

                # create model using the body
                Model.create body
            ).then((row) ->
                res.limeSend row
            ).catch((err) ->
                next err
            )

    update: ->
        (req, res, next) ->
            Promise.try( ->
                # no data
                throw new error.InvalidArgument('data is missing') unless req.limeApi.body?

                # remove id
                body = req.limeApi.body
                delete body.id if body.id

                # find model using the id
                Model.findById(req.params.id).then((row) ->
                    row.updateAttributes(body).then( ->
                        res.limeSend row
                    )
                )
            ).catch((err) ->
                next err
            )

    destroy: ->
        (req, res, next) ->
            Model.findById(req.params.id).then((row) ->
                row.destroy().then( ->
                    res.limeSend row
                )
            ).catch((err) ->
                next err
            )
