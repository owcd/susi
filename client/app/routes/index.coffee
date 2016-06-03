`import Ember from 'ember'`

IndexRoute = Ember.Route.extend
    beforeModel: ->
        @transitionTo 'tournaments'

`export default IndexRoute`