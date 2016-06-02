rqf = require 'rqf'

# the base model
BaseModel = rqf 'lib/sequelize/model/base'

# exports
module.exports = (sequelize, DataTypes) ->
    # define the class
    class Group extends BaseModel
        # define fields
        @fields =
            name:
                type: DataTypes.STRING(50)
                validate:
                    len: [3, 50]

        # define table name
        @tableName = 'groups'

        # associate to other models
        @associate: (models) ->
            # belongs to relationship
            @belongsTo models.Tournament,
                as: 'tournament'
                foreignKey: 'tournament_id'

            # hasMany groups
            @hasMany models.Team,
                as: 'teams'
                foreignKey: 'group_id'

    # define
    Model = Group.define sequelize
    Model
