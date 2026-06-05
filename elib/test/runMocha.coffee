process.env.NODE_ENV = process.env.NODE_ENV or 'test'
global.TEST_ENV = if process.env.TEST_ENV? then process.env.TEST_ENV.split(' ') else []
exit = process.exit

process.exit = (code) ->
    setTimeout( ->
        exit()
    , 200)

require '../node_modules/mocha/bin/_mocha'