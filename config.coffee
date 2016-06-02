convict = require 'convict'
fs = require 'fs'
path = require 'path'
_ = require 'lodash'

# define configuration
config = convict
    env:
        doc: "The applicaton environment."
        format: ["production", "development", "test"]
        default: "development"
        env: "NODE_ENV"
    server:
        ip:
            doc: "IP address to bind"
            format: 'ipaddress'
            default: '0.0.0.0'
        port:
            doc: "port to bind"
            format: 'port'
            default: 8080
    database:
        host:
            doc: "Database host name/IP"
            format: String
            default: 'localhost'
            arg: 'dbhost'
            env: 'DBHOST'
        username:
            doc: "Database username"
            format: String
            default: 'susi'
            arg: 'dbuser'
            env: 'DBUSER'
        password:
            doc: "Database password"
            format: String
            default: 'susi'
            arg: 'dbpass'
            env: 'DBPASS'
        name:
            doc: "Database name"
            format: String
            default: 'susi'
    session:
        name:
            doc: "Session name"
            format: String
            default: 'sid'
        secret:
            doc: "Session secret"
            format: String
            default: 'F5rvJyHDgDt5rm34'
    speaker:
        audio:
            doc: "Audio files path"
            format: String
            default: null

###
var env = conf.get('env');
conf.loadFile('./config/' + env + '.json');
###
files = fs.readdirSync(path.join(__dirname, 'config'))
_.each files, (file) ->
    config.loadFile(path.join(__dirname, 'config', file))

# config validation
config.validate
    strict: true

# exports
module.exports = config