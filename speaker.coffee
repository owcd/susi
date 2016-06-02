Speaker = require 'speaker'
Promise = require 'bluebird'
ffmpeg = require 'fluent-ffmpeg'
path = require 'path'
stream = require 'stream'

files = []
court = Math.floor((Math.random() * 4)) + 1
prepare = true
if Math.random() > 0.5
    files.push 'courts_' + court + '_prepare.wav'
else
    prepare = false
    files.push 'courts_' + court + '_playing.wav'

# pick challenging team
team1 = Math.floor((Math.random() * 9)) + 1
files.push 'teams_' + team1 + '_vs.wav'

if prepare
    files.push 'prepare_and.wav'
else
    files.push 'playing_vs.wav'

team2 = Math.floor((Math.random() * 4)) + 1
team2 = (team2 % 4) + 1 if team2 is team1
files.push 'teams_vs_' + team2 + '.wav'

speaker = new Speaker(
    channels: 2
    bitDepth: 16
    sampleRate: 44100
)

pass = new stream.PassThrough()
pass.pipe speaker

Promise.each(files, (file) ->
    #console.log 'convert', file
    ffstream = new stream.PassThrough()
    command = ffmpeg()
        .input(path.join('/media/move/susi/audio', file))
        .audioCodec('pcm_s16le')
        .audioChannels(2)
        .audioFrequency(44100)
        .noVideo()
        .output(ffstream)
        .format('u16le')
        .on('start', (commandLine) ->
            console.log('Spawned Ffmpeg with command: ' + commandLine)
        )

    ffstream.on 'data', (chunk) ->
        pass.write chunk

    # promise
    new Promise (resolve) ->
        command.on 'end', resolve
        command.run()
).then( ->
    new Promise (resolve) ->
        pass.once 'drain', resolve
).then( ->
    Promise.delay(1000)
)

speaker.on 'flush', ->
    console.log 'flushed!'

pass.on 'drain', ->
    return
    console.log 'dry'
