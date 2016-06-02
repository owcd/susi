`import Ember from 'ember'`
`import DS from 'ember-data'`

Team = DS.Model.extend
    name: DS.attr()
    number: DS.attr()

    # relationships
    tournament: DS.belongsTo 'Tournament'
    group: DS.belongsTo 'Group'

`export default Team`
