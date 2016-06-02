rqf = require 'rqf'

# the base model
BaseModel = rqf 'lib/sequelize/model/base'

# exports
module.exports = (sequelize, DataTypes) ->
    # define the class
    class Round extends BaseModel
        # define fields
        @fields =
            start: DataTypes.DATE
            end: DataTypes.DATE

        # define table name
        @tableName = 'rounds'

        # associate to other models
        @associate: (models) ->
            # belongs to relationship
            @belongsTo models.Tournament,
                as: 'tournament'
                foreignKey: 'tournament_id'

            # hasMany games
            @hasMany models.Game,
                as: 'games'
                foreignKey: 'round_id'

    # define
    Model = Round.define sequelize
    Model
