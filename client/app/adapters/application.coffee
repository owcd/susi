`import DS from 'ember-data'`

ApplicationAdapter = DS.JSONAPIAdapter.extend
    namespace: 'api'

    #override JSON API recommendation
    # http://jsonapi.org/recommendations/#naming
    ###
    pathForType: (modelName) ->
        path = Ember.String.underscore(modelName)
        Ember.String.pluralize(path)
    ###

`export default ApplicationAdapter`

