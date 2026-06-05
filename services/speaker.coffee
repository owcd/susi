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
    options.roundBreak = 5 unless options.roundBreak? # break between rounds in minutes
    options.playAnnouncementOffset = 2 unless options.playAnnouncementOffset? # offset of the play announcement
    options.sponsoringDelay = 3 unless options.sponsoringDelay? # delay in minutes for the sponsoring announcement, set to 0 to disable

    # 8 minutes round with 7 minutes break
    options.roundBreak = 7
    options.playAnnouncementOffset = 4

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
                date = moment(round.start).subtract(options.roundBreak - options.playAnnouncementOffset, 'minutes')
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

            # generate sponsor announcement
            date = moment(round.start)
            # console.log('starting minute & hour', date.minute(), date.hour())
            if options.sponsoringDelay > 0 && date.minute() < 10
                generators.announceSponsors(date.hour() % 2).then((buffer) ->
                    date = moment(round.start).add(options.sponsoringDelay, 'minutes')
                    date = date.subtract(config.get('speaker.timewarp'), 'minutes') if config.get('speaker.timewarp') > 0
                    schedule.scheduleJob(date.toDate(), _play.bind(null, buffer))
                )


            # generate round end warning
            generators.roundEndWarning().then((buffer) ->
                date = moment(round.end).subtract(options.roundBreak + 1, 'minutes')
                date = date.subtract(config.get('speaker.timewarp'), 'minutes') if config.get('speaker.timewarp') > 0
                #date = moment().add(55, 'seconds').toDate()
                schedule.scheduleJob(date.toDate(), _play.bind(null, buffer))
            )

            # generate round end
            generators.roundEnd().then((buffer) ->
                date = moment(round.end).subtract(options.roundBreak * 60 + 6, 'seconds')
                date = date.subtract(config.get('speaker.timewarp'), 'minutes') if config.get('speaker.timewarp') > 0
                #date = moment().add(60, 'seconds').toDate()
                schedule.scheduleJob(date.toDate(), _play.bind(null, buffer))
            )

        )
    ).catch((err) ->
        console.error err
    )

# play the stream
_playStream = (stream) ->
    stream.on 'end', () -> stream.unpipe speaker
    stream.pipe speaker

# play the buffer
_play = (buffer) ->
    speaker.write buffer
