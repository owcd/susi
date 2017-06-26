rqf = require 'rqf'
_ = require 'lodash'
schedule = require 'node-schedule'
Speaker = require 'speaker'
Promise = require 'bluebird'

# config
config = rqf 'config'

# require models
models = rqf 'models'
sequelize = models.sequelize
Round = models.Round
Game = models.Game
Court = models.Court

# generators
generators = rqf 'lib/speaker/generators'

# initialize the speaker
speaker = new Speaker(
    channels: 2
    bitDepth: 16
    sampleRate: 44100
)

Round.findById(28).then((round) ->
    # find the games
    Game.findAll(
        where:
            round_id: round.id
        include: [
            model: Court
            as: 'court'
        ]
        order: [[sequelize.col('court.number'), 'ASC']]
    ).then((games) ->
        # only proceed in case there are games!
        return unless games.length > 0

        # generate the sequence
        Promise.all([
            generators.prepareGames(games)
            generators.playGames(games)
            generators.roundStart()
            generators.roundEndWarning()
            generators.roundEnd()
        ]).each((buffer) ->
            speaker.write buffer
        )
    )
).catch((err) ->
    console.error err
)
