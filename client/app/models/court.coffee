`import Ember from 'ember'`
`import DS from 'ember-data'`

Court = DS.Model.extend
    name: DS.attr()
    number: DS.attr()

    # relationships
    tournament: DS.belongsTo 'Tournament'

`export default Court`
