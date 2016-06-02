`import Ember from 'ember'`
`import DS from 'ember-data'`

Group = DS.Model.extend
    name: DS.attr()

    # relationships
    tournament: DS.belongsTo 'Tournament'
    teams: DS.hasMany 'Team'

`export default Group`
