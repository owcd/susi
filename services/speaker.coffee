rqf = require 'rqf'
_ = require 'lodash'
moment = require 'moment'
schedule = require 'node-schedule'
Speaker = require 'speaker'
Promise = require 'bluebird'
ffmpeg = require 'fluent-ffmpeg'
path = require 'path'
stream = require 'stream'

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

module.exports = (options = {}) ->
    # set defaults
    options.prepareAnnouncement = 5 unless options.prepareAnnouncement?

    # set repeating interval
    setInterval(_scheduleRound.bind(null, options), 60 * 1000)
    _scheduleRound options

# schedule the next rounds
_scheduleRound = (options) ->
    # define starting timespan
    from = moment().add(options.prepareAnnouncement + 1, 'minutes')
    to = moment(from).add(1, 'minutes')

    # timewarp
    if config.get('speaker.timewarp') > 0
        from = from.add(config.get('speaker.timewarp'), 'minutes')
        to = to.add(config.get('speaker.timewarp'), 'minutes')

    # query for round
    return Round.findAll(
        where:
            start:
                $gte: from.toDate()
                $lt: to.toDate()
    ).each((round) ->
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

            # generate game prepare
            generators.prepareGames(games).then((buffer) ->
                date = moment(round.start).subtract(options.prepareAnnouncement, 'minutes')
                date = date.subtract(config.get('speaker.timewarp'), 'minutes') if config.get('speaker.timewarp') > 0
                #date = moment().add(5, 'seconds').toDate()
                schedule.scheduleJob(date.toDate(), _play.bind(null, buffer))
            )

            # generate game play
            generators.playGames(games).then((buffer) ->
                date = moment(round.start).subtract(1, 'minutes')
                date = date.subtract(config.get('speaker.timewarp'), 'minutes') if config.get('speaker.timewarp') > 0
                #date = moment().add(30, 'seconds').toDate()
                schedule.scheduleJob(date.toDate(), _play.bind(null, buffer))
            )

            # generate round start
            generators.roundStart().then((buffer) ->
                date = moment(round.start)
                date = date.subtract(config.get('speaker.timewarp'), 'minutes') if config.get('speaker.timewarp') > 0
                #date = moment().add(50, 'seconds').toDate()
                schedule.scheduleJob(date.toDate(), _play.bind(null, buffer))
            )

            # generate round end warning
            generators.roundEndWarning().then((buffer) ->
                date = moment(round.end).subtract(2, 'minutes')
                date = date.subtract(config.get('speaker.timewarp'), 'minutes') if config.get('speaker.timewarp') > 0
                #date = moment().add(55, 'seconds').toDate()
                schedule.scheduleJob(date.toDate(), _play.bind(null, buffer))
            )

            # generate round end
            generators.roundEnd().then((buffer) ->
                date = moment(round.end).subtract(66, 'seconds')
                date = date.subtract(config.get('speaker.timewarp'), 'minutes') if config.get('speaker.timewarp') > 0
                #date = moment().add(60, 'seconds').toDate()
                schedule.scheduleJob(date.toDate(), _play.bind(null, buffer))
            )

        )
    ).catch((err) ->
        console.error err
    )

# play the buffer
_play = (buffer) ->
    speaker.write buffer
