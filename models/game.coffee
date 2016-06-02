rqf = require 'rqf'

# the base model
BaseModel = rqf 'lib/sequelize/model/base'

# exports
module.exports = (sequelize, DataTypes) ->
    # define the class
    class Game extends BaseModel
        # define fields
        @fields = {}

        # define table name
        @tableName = 'games'

        # associate to other models
        @associate: (models) ->
            # belongs to tournament
            @belongsTo models.Court,
                as: 'court'
                foreignKey: 'court_id'

            # belongs to a round
            @belongsTo models.Round,
                as: 'round'
                foreignKey: 'round_id'

            # belongs to first team
            @belongsTo models.Team,
                as: 'team1'
                foreignKey: 'team1_id'

            # belongs to second team
            @belongsTo models.Team,
                as: 'team2'
                foreignKey: 'team2_id'

    # define
    Model = Game.define sequelize
    Model
