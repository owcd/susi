rqf = require 'rqf'
fs = require 'fs'
path = require 'path'
Sequelize = require 'sequelize'
Umzug = require 'umzug'

# load the configuration
config = rqf 'config'

# connect
sequelize = new Sequelize(config.get('database.name'), config.get('database.username'), config.get('database.password'),
    host: config.get('database.host')
    dialect: 'mysql'
)

# load models
db = {}
fs.readdirSync(__dirname).filter((file) ->
    file.indexOf('.') > 0 and file isnt path.basename(module.filename) and file.slice(-7) is '.coffee'
).forEach((file) ->
    console.log 'import', file
    model = sequelize['import'](path.join(__dirname, file))
    db[model.name] = model
)

# associate models
Object.keys(db).forEach (modelName) ->
    if db[modelName].associate
        db[modelName].associate db

# create migrator
migrator = new Umzug
    storage: 'sequelize'
    storageOptions:
        sequelize: sequelize
    migrations:
        params: [ sequelize.getQueryInterface(), Sequelize ]
        path: 'migrations'
        pattern: /\.coffee$/

# migrate async
migrator.up().then((migrations) ->
    console.log 'migrations complete'
).catch((err) ->
    console.error 'error migrating DB: ', err
)

# set sequelize
db.sequelize = sequelize
db.Sequelize = Sequelize

# export
module.exports = db
