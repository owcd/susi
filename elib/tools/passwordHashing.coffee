bcrypt = require 'bcrypt'
Q = require 'bluebird-q'
rqf = require 'rqf'

serverConfig = rqf "server.config"

generateSalt = () ->
    deferred = Q.defer()
    bcrypt.genSalt(10, deferred.makeNodeResolver())
    deferred.promise

hashPassword = (password, salt) ->
    deferred = Q.defer()
    bcrypt.hash(password, salt, deferred.makeNodeResolver())
    deferred.promise

comparePasswords = (password, hash) ->
    deferred = Q.defer()
    bcrypt.compare(password, hash, deferred.makeNodeResolver())
    deferred.promise
    
exports.encryptPassword = (password) ->
    # 1- first encrypt using the server salt
    hashPassword(password, serverConfig.server.salt)
    .then((serverHashedPassword) ->
        password = serverHashedPassword
        generateSalt()
    ).then((generatedSalt) ->
        hashPassword(password, generatedSalt)
    )

exports.authenticatePassword = (password, encryptedPassword) ->
    hashPassword(password, serverConfig.server.salt)
    .then((hash) ->
        comparePasswords hash, encryptedPassword
    )

exports.passwordIsOurs = (encryptedPassword) ->
    try
        rounds = bcrypt.getRounds(encryptedPassword)
        rounds > 0
    catch e
        false
