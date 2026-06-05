path = require 'path'

# export
module.exports = (writer, config) ->
    fonts = {}

    # getter
    (font, variation) ->
        # define key
        variation = variation or 'regular'
        key = [font, variation].join '-'

        # font loaded?
        if not fonts[key]? and config.types[font][variation]?
            fonts[key] = writer.getFontForFile path.join(config.path, config.types[font][variation])

        # return
        fonts[key]