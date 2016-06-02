Promise = require 'bluebird'
rqf = require 'rqf'

# require the models
models = rqf 'models'

# data definition
tournamentsGroupsTeamsAndCourts = [
    ['Beltane Parkvolley 2016', '2016-06-03', [
        ['Vereinscup', [
            'Happy Oceans'
            'Quaker ööö'
            'Quaker döö'
            'Skiklub Unterägeri'
            'Ruderclub Cham'
            'Reha Zentrum Cham'
            'Smash-Monsters'
            'Parcom'
            'Contis'
        ]]
    ], [
        'Raiffeisen / WWZ'
        'HCNClean'
        'ClimaNova'
        'Restaurant Rössli'
    ]]
    ['Beltane Parkvolley 2016', '2016-06-04', [
        ['Mixed 3:3', [
            'Dawai'
            'SCHNIPO'
            'Gürklis'
            'Spaghettisultan'
            'GIN TONIC'
            'nee nee du'
            'Orale!'
            'Merry T\'s'
            'Spacecakes'
            'dream team'
            'Softic'
            'KillerPandas'
            'Kampf Zwerge'
            'Monday-Crascher'
            'Touch and go'
            'NTBN'
            'TIP TOP'
        ]]
        ['Plausch 4:4', [
            'Figugegl'
            'Abnox'
            'Pfadi Hü'
            'D\'Hechtä'
            'Ha Chopfweh'
            'Team Capra'
            'Pläuschler'
            'Chi\'ll'
        ]]
    ], [
        'Raiffeisen'
        'WWZ'
        'HCNClean'
        'ClimaNova'
        'Restaurant Rössli'
    ]]
]

# export the migrations
module.exports =
    up: (migration, Sequelize) ->
        Promise.each(['Tournament', 'Court', 'Group', 'Round', 'Team', 'Game'], (key) ->
            models[key].sync()
        ).then( ->
            Promise.each(tournamentsGroupsTeamsAndCourts, (tournamentGroupsTeamsAndCourts) ->
                console.log tournamentGroupsTeamsAndCourts
                models.Tournament.importFromData tournamentGroupsTeamsAndCourts...
            )
        )

    down: ->
