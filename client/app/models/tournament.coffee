`import Ember from 'ember'`
`import DS from 'ember-data'`

Tournament = DS.Model.extend
    name: DS.attr()
    date: DS.attr()

    # relationships
    rounds: DS.hasMany 'Round'
    courts: DS.hasMany 'Court'
    groups: DS.hasMany 'Group'

`export default Tournament`
