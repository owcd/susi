`import Ember from 'ember'`

TournamentsTournamentGameComponent = Ember.Component.extend
    store: Ember.inject.service 'store'
    classNames: ['row', 'tournament-game']

    hasTeams: ( ->
        @get('game.team1.id')? and @get('game.team2.id')?
    ).property('game.team1', 'game.team2')

`export default TournamentsTournamentGameComponent`
