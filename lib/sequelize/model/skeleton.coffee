_ = require 'lodash'

module.exports = class Skeleton
    # defaults
    filters: []
    fields: []
    requiredFields: []
    include: []
    sort: []
    limit: 1000
    api: 'all'

    # private properties
    _model: null

    # construct
    constructor: (@_model) ->
        # allow everything on all attributes
        @fields = @filters = @sort = _.keys @_model.attributes

        # primary key fields are always required
        @requiredFields = @_model.primaryKeyAttributes

        # add included objects
        @include = _.keys @_model.associations
