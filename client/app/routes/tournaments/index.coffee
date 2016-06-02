`import Ember from 'ember'`

TournamentsIndexRoute = Ember.Route.extend
    model: ->
        @store.query('tournament',
            sort: 'date'
        )

`export default TournamentsIndexRoute`