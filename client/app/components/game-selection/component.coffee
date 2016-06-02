`import Ember from 'ember'`

GameSelectionComponent = Ember.Component.extend
    store: Ember.inject.service 'store'
    classNames: ['row']

    gameChangeObserver: ( ->
        @setProperties
            group: @get('game.team1.group.id')
            team1: @get('game.team1.id')
            team2: @get('game.team2.id')
    ).observes('game').on('init')

    teamChangeObserver: ( ->
        game = @get('game')
        ['team1', 'team2'].forEach (key) =>
            team = null
            team = @get('store').peekRecord 'team', @get(key) if @get(key)?
            game.set key, team
    ).observes('team1', 'team2')

    teams: ( ->
        if @get('group')?
            group = @get('groups').findBy 'id', @get('group')
            if group?
                group.get('teams')
            else
                []
        else
            []
    ).property('groups', 'group')

`export default GameSelectionComponent`
