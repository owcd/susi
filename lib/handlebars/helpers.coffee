_ = require 'lodash'

# exports hbs
module.exports = (hbs) ->
    # blocks
    blocks = {}

    # extend helper
    hbs.registerHelper 'extend', (name, context) ->
        block = blocks[name]
        block = blocks[name] = [] unless block
        block.push(context.fn(@))
        null

    # block helper
    hbs.registerHelper 'block', (name) ->
        val = (blocks[name] || []).join('\n')
        blocks[name] = []
        val

    # safe helper
    hbs.registerHelper 'safe', (content) ->
        new hbs.SafeString content if content?

    # meta tag helper
    hbs.registerHelper 'meta', (data) ->
        meta = ''
        _.each data, (tags, name) ->
            if _.isObject tags
                _.each tags, (value, key) ->
                    meta += '<meta ' + name + '="' + key + '" content="' + _.escape(value) + '" />'
                    meta += "\n    "
            else
                meta += '<meta ' + name + '="' + tags + '" />'
                meta += "\n    "

        # safe string
        new hbs.SafeString meta
