rqf = require 'rqf'

# the base model
BaseModel = rqf 'lib/sequelize/model/base'

# exports
module.exports = (sequelize, DataTypes) ->
    # define the class
    class Court extends BaseModel
        # define fields
        @fields =
            number:
                type: DataTypes.INTEGER
                validate:
                    isInt: true
            name:
                type: DataTypes.STRING(50)
                validate:
                    len: [3, 50]

        # define table name
        @tableName = 'courts'

        # associate to other models
        @associate: (models) ->
            # belongs to relationship
            @belongsTo models.Tournament,
                as: 'tournament'
                foreignKey: 'tournament_id'

    # define
    Model = Court.define sequelize
    Model
