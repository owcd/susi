`import Ember from 'ember'`
`import DS from 'ember-data'`

Round = DS.Model.extend
    start: DS.attr()
    end: DS.attr()

    # relationships
    tournament: DS.belongsTo 'Tournament'
    games: DS.hasMany 'Game'

`export default Round`
