`import Ember from 'ember';`
`import config from './config/environment';`

Router = Ember.Router.extend
    location: config.locationType

Router.map ->
    # tournaments route
    @route 'tournaments', ->
        @route 'tournament',
            path: '/:tournament_id'

    # example route
    @route 'example'

`export default Router`
