`import Ember from 'ember'`

TournamentsTournamentRoundsComponent = Ember.Component.extend
    store: Ember.inject.service 'store'
    classNames: ['tournament-rounds']

    actions:
        addRound: ->
            round = @get('store').createRecord 'round'
            @get('rounds').pushObject round

`export default TournamentsTournamentRoundsComponent`
