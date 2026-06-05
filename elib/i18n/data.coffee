# i18n country and currency data module
# extends the basic i18n functionality

_ = require 'underscore'
countryData = require 'country-data'
vatrates = require 'vatrates'
getSymbol = require 'currency-symbol-map'
rqf = require 'rqf'

# tools
safeAlias = require 'elib/tools/safeAlias'
error = require 'elib/error'

# locales
cache = {}

# export
module.exports = exports = (locale) ->
    # cached?
    unless _.has(cache, locale)
        # load inter
        inter = require('inter').load(locale)

        # loop countries
        countries = []
        _.each inter.countries, (country) ->
            # the defaults
            currency = 'EUR'
            tax = 0

            # known country
            if countryData.countries[country.id]?.currencies?
                currency = _.first countryData.countries[country.id].currencies

            # taxable country
            if country.id in ['CH', 'LI']
                tax = 8
            else if vatrates[country.id]?
                tax = vatrates[country.id].rates.standard

            # push to countries
            countries.push
                name: country.displayName
                code: country.id
                currency: currency
                tax: tax

        # sort countries by their name
        countries.sort (a, b) ->
            a = safeAlias.chars a.name
            b = safeAlias.chars b.name
            if a < b
                -1
            else if a > b
                1
            else
                0

        # loop currencies
        currencies = []
        _.each inter.currencies, (currency) ->
            symbol = currency.id
            symbol = getSymbol(currency.id) if getSymbol(currency.id)? and getSymbol(currency.id) isnt '?'
            symbol = 'Fr.' if currency.id is 'CHF' # force
            currencies.push
                name: currency.displayName
                code: currency.id
                symbol: symbol

        # loop languages
        languages = []
        _.each inter.languages, (language) ->
            languages.push
                name: language.displayName
                code: language.id

        # create i18n for locale
        cache[locale] =
            # the locale
            locale: locale

            # access to inter
            inter: inter

            # the countries
            countries: countries

            # the currencies
            currencies: currencies

            # the languages
            languages: languages

            # get country
            getCountry: (code) ->
                _.find @countries, (country) -> country.code is code

            # has the country?
            hasCountry: (code) ->
                @getCurrency(code) isnt null

            # get currency
            getCurrency: (code) ->
                _.find @currencies, (currency) -> currency.code is code

            # has the currency?
            hasCurrency: (code) ->
                @getCurrency(code) isnt null

            # get language
            getLanguage: (code) ->
                _.find @languages, (language) -> language.code is code

            # has the language?
            hasLanguage: (code) ->
                @getLanguage(code) isnt null

    # return
    cache[locale]
