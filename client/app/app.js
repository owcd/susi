import Ember from 'ember';
import DS from 'ember-data';
import Resolver from './resolver';
import loadInitializers from 'ember-load-initializers';
import config from './config/environment';

let App;

Ember.MODEL_FACTORY_INJECTIONS = true;

App = Ember.Application.extend({
  modulePrefix: config.modulePrefix,
  podModulePrefix: config.podModulePrefix,
  rootElement: '#app',
  Resolver
});

App.ApplicationAdapter = DS.JSONAPIAdapter.extend({
    namespace: 'api'
});

loadInitializers(App, config.modulePrefix);

export default App;
