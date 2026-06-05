###
    "some_key" : [ null, "%(text)s %(keys)d key", "%(text)s %(keys)d keys" ]
    i18n.translate('some_key')
        .ifPlural(n)
        .fetch({
            keys: n
            text: 'some text'
        })
###

# libs
_ = require 'underscore'
_s = require 'underscore.string'
rqf = require 'rqf'
Q = require 'bluebird-q'
fs = require 'q-io/fs'
Jed = require 'jed'
path = require 'path'
moment = require 'moment'

# server config
serverConfig = rqf 'server.config'

# error
error = require 'elib/error'

# the timestamp
timestamp = 0

# information
info = null

# cached apis
cache = {}

# load the data
load = () ->
    fs.read(path.join(serverConfig.translation.base, 'index.json')).then((content) ->
        # promises
        promises = []

        # parse the data
        info = JSON.parse content

        # remeber load time
        info.loaded = Date.now()

        # rebuild cache?
        unless info.time is timestamp
            timestamp = info.time
            _.each info.locales, (locale) ->
                promises.push create locale

        # fulfill all promises
        Q.all promises
    ) if !info? or moment(info.loaded).add(1, 'minute').isBefore(new Date)

# load locale
get = (locale) ->

    # re-load, but don't wait!
    load()

    # locale unkown
    unless _.has cache, locale
        # split
        [language, country] = locale.split '-'

        # try default country of language
        if _.has serverConfig.locale.languages, language
            country = serverConfig.locale.languages[language]
            locale = [language, country].join '-'

            # still no locale, first matching country of language
            unless _.has cache, locale
                country = _.find(serverConfig.locale.languages[language], (c) ->
                    _.has cache, [language, c].join('-')
                )
                locale = [language, country].join '-'

    # unavailable
    throw new error.InvalidArgument('no and no similar locale available') unless _.has cache, locale

    # return
    cache[locale]

# create locale
create = (locale) ->
    # valid locale
    throw new error.InvalidArgument('locale is invalid') unless _.contains info.locales, locale

    # init promises
    promises = []
    _.each info.domains, (domain) ->
        promises.push fs.read(path.join(serverConfig.translation.base, locale, domain + '.json'))

    # build api
    Q.all(promises).then((results) ->
        # init messages
        messages = {}

        # loop results
        _.each results, (data) ->
            messages = _.extend messages, JSON.parse data

        # create translations
        translations = {}
        _.each messages, (message, key) ->
            unless _s.endsWith key, '_plural'
                translations[key] = [null, message]
                translations[key].push messages[key + '_plural'] if _.has messages, key + '_plural'

        # add translation information
        translations[''] =
            domain: 'messages'
            lang: locale
            plural_forms: "nplurals=2; plural=(n != 1);"

        # build the api cache and return
        cache[locale] = new Jed
            domain: 'messages'

            locale_data:
                messages: translations

        # set the used locale
        cache[locale].locale = locale
        cache[locale].language = language locale
        cache[locale].country = country locale

        # get additional i18n data
        cache[locale].getData = () ->
            rqf.dir(__dirname)('data')(locale)

        # return
        cache[locale]
    )

# retrieve a locale
module.exports = (locale) ->
    get locale

# express plugin
module.exports.express = (req, res, next) ->
    try
        i18n = get req.locale
        req.i18n = res.locals.i18n = i18n
        next()
    catch e
        next e

# helpers
locale = module.exports.locale = (language, country) ->
    if country?
        [language, country].join('-')
    else
        language
language = module.exports.language = (locale) -> locale.split('-')[0]
country = module.exports.country = (locale) -> locale.split('-')[1]

# export shortcuts
languages = module.exports.languages = _.keys serverConfig.locale.languages
countries = module.exports.countries = serverConfig.locale.countries

# list of officially supported locale combinations
locales = module.exports.locales = []
_.each serverConfig.locale.languages, (countries, language) ->
    _.each countries, (country) ->
        locales.push locale(language, country)

# initial load
load()