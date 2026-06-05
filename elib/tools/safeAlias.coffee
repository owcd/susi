# require
_ = require 'underscore'

# define vars
dict = 'Š|S, Œ|O, Ž|Z, š|s, œ|oe, ž|z, Ÿ|Y, ¥|Y, µ|u, À|A, Á|A, Â|A, Ã|A, Ä|Ae, Å|A, Æ|A, Ç|C, È|E, É|E, Ê|E, Ë|E, Ì|I, Í|I, Î|I, Ï|I, Ð|D, Ñ|N, Ò|O, Ó|O, Ô|O, Õ|O, Ö|Oe, Ø|O, Ù|U, Ú|U, Û|U, Ü|Ue, Ý|Y, ß|s, à|a, á|a, â|a, ã|a, ä|ae, å|a, æ|a, ç|c, è|e, é|e, ê|e, ë|e, ì|i, í|i, î|i, ï|i, ð|o, ñ|n, ò|o, ó|o, ô|o, õ|o, ö|oe, ø|o, ù|u, ú|u, û|u, ü|ue, ý|y, ÿ|y, ß|ss, ă|a, ş|s, ţ|t, ț|t, Ț|T, Ș|S, ș|s, Ş|S'
delimiter = '_'
replace = true

# parse dictionary
dictionary = {}
_.each dict.split(', '), (element) ->
    part = element.split '|'
    dictionary[part[0]] = part[1]

exports.simple = (str)->
    if str
        str.replace(/[^\w\s-]/g, '').replace(/([A-Z])/g, '$1').replace(/[-_\s]+/g, '-').toLowerCase()
    else
        no

exports.chars = (str)->
    if str
        str = str.toLowerCase()

        #find chars fo replace by dictionary
        if replace
            dictionaryStr = _.keys(dictionary).join('')
            charsToReplace = str.match(new RegExp("[#{dictionaryStr}]+", 'ig'))
            if charsToReplace? && charsToReplace.length
                charsToReplace = _.uniq(charsToReplace.join('').split(''))
                _.each(charsToReplace, (char)->
                    if( typeof dictionary[char] == 'string')
                        str = str.replace(new RegExp("[#{char}]", 'ig'), dictionary[char])
                )

        rule = new RegExp('([0-9]|[a-z])', 'ig');
        unless rule.test(delimiter)
            delimiter = '\\' + delimiter

        sys = ''
        sysData = str.match(new RegExp("[#{delimiter}]{1}[0-9]+$", 'ig'))
        if (sysData? and sysData.length > 0)
            sys = sysData[0]

        str.match(/[^-^_^\s^\W]+/ig).join('-') + sys
    else
        no