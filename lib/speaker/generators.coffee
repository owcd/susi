rqf = require 'rqf'
streamBuffers = require 'stream-buffers'
Promise = require 'bluebird'
ffmpeg = require 'fluent-ffmpeg'
path = require 'path'
_ = require 'lodash'
stream = require 'stream'

# config
config = rqf 'config'

# prepare the games
module.exports.prepareGames = (games) ->
    files = []
    Promise.each(games, (game) ->
        # this option uses a continue message instead of the full prepare message
        if files.length > 0
            # files.push 'prepare_and.wav'
            files.push 'courts_' + game.court_id + '_cont.wav'
        else
            files.push 'courts_' + game.court_id + '_prepare.wav'
        #files.push 'courts_' + game.court_id + '_prepare.wav'
        files.push 'teams_' + game.team1_id + '_vs.wav'
        #files.push 'teams_' + game.team1_id + '.wav'
        files.push 'prepare_and.wav'
        files.push 'teams_vs_' + game.team2_id + '.wav'
        #files.push 'teams_' + game.team2_id + '.wav'
    ).then( ->
        _prepareAudioBuffer(files)
    )

# prepare the games
module.exports.playGames = (games) ->
    files = []
    Promise.each(games, (game) ->
        # this option uses a continue message instead of the full play message
        if files.length > 0
            files.push 'courts_' + game.court_id + '_cont.wav'
        else
            files.push 'courts_' + game.court_id + '_playing.wav'
        #files.push 'courts_' + game.court_id + '_playing.wav'
        files.push 'teams_' + game.team1_id + '_vs.wav'
        #files.push 'teams_' + game.team1_id + '.wav'
        files.push 'playing_vs.wav'
        files.push 'teams_vs_' + game.team2_id + '.wav'
        #files.push 'teams_' + game.team2_id + '.wav'
    ).then( ->
        _prepareAudioBuffer(files)
    )

# round end warning
module.exports.roundEndWarning = ->
    _prepareAudioBuffer(['round_end_warning.wav'])

# round end
module.exports.roundEnd = ->
    _prepareAudioBuffer(['round_end.wav'])

# round start
module.exports.roundStart = ->
    _prepareAudioBuffer(['round_start.wav'])

# sponsoring
module.exports.announceSponsors = (full) ->
    files = ['sponsoren_allgemein.wav']
    # if full
    #    files.push 'sponsoren2.wav'
    _prepareAudioBuffer(files)


# prepare the audio buffer
_prepareAudioBuffer = (files) ->
    files.unshift 'silence.wav' # insert silence part
    buffers = []
    Promise.each(files, (file) ->
        streamBuffer = new streamBuffers.WritableStreamBuffer()
        buffers.push streamBuffer
        new Promise (resolve, reject) ->
            ffmpeg()
                .input(path.join(config.get('speaker.audio'), file))
                .audioCodec('pcm_s16le')
                .audioChannels(2)
                .audioFrequency(44100)
                .noVideo()
                .output(streamBuffer)
                .format('u16le')
                .on('start', (commandLine) ->
                        console.log('Spawned Ffmpeg with command: ' + commandLine)
                    ).on('error', reject)
                .on('end', resolve)
                .run()
    ).then( ->
        Buffer.concat(_.map(buffers, (buffer) -> buffer.getContents()))
    )

###
_prepareAudioStream = (files) ->
    pass = new stream.PassThrough({highWaterMark: 1 * 1024 * 1024})
    Promise.each(files, (file) ->
        ffstream = new stream.PassThrough()
        command = ffmpeg()
            .input(path.join(config.get('speaker.audio'), file))
            .audioCodec('pcm_s16le')
            .audioChannels(2)
            .audioFrequency(44100)
            .noVideo()
            .output(ffstream)
            .format('u16le')
            .on('start', (commandLine) ->
                console.log('Spawned Ffmpeg with command: ' + commandLine)
            )

        # forward the data
        ffstream.on 'data', (chunk) ->
            pass.write chunk

        # promise
        new Promise (resolve, reject) ->
            ffstream.on 'end', resolve
            ffstream.on 'error', reject
            command.run()
    ).then( ->
        pass
    )
###
