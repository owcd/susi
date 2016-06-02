rqf = require 'rqf'
Promise = require 'bluebird'

# the base model
BaseModel = rqf 'lib/sequelize/model/base'

# exports
module.exports = (sequelize, DataTypes) ->
    # define the class
    class Tournament extends BaseModel
        @fields =
            name:
                type: DataTypes.STRING(50)
                validate:
                    len: [3, 50]
            date: DataTypes.DATEONLY

        @tableName = 'tournaments'

        # associate to other models
        @associate: (models) ->
            # hasMany courts
            @hasMany models.Court,
                as: 'courts'
                foreignKey: 'tournament_id'

            # hasMany groups
            @hasMany models.Group,
                as: 'groups'
                foreignKey: 'tournament_id'

        # import tournament from data
        @importFromData: (name, date, groupsAndTeams, courts) ->
            # import the models
            models = rqf 'models'

            @create(
                name: name
                date: date
            ).then((tournament) ->
                # create groups
                Promise.each(groupsAndTeams, (groupAndTeams) ->
                    [group, teams] = groupAndTeams
                    models.Group.create(
                        name: group
                        tournament_id: tournament.id
                    ).then((group) ->
                        Promise.each(teams, (team, index) ->
                            models.Team.create(
                                name: team
                                number: index + 1
                                group_id: group.id
                                tournament_id: tournament.id
                            )
                        )
                    )
                ).then( ->
                    Promise.each(courts, (court, index) ->
                        models.Court.create(
                            name: court
                            number: index + 1
                            tournament_id: tournament.id
                        )
                    )
                ).then( ->
                    tournament
                )
            )

    # define
    Model = Tournament.define sequelize
    Model