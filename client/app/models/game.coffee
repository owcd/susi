`import Ember from 'ember'`
`import DS from 'ember-data'`

Game = DS.Model.extend
    # relationships
    court: DS.belongsTo 'Court'
    round: DS.belongsTo 'Round'
    team1: DS.belongsTo 'Team'
    team2: DS.belongsTo 'Team'

    # is the game valid?
    isPlayable: ( ->
        @get('round.id')? and @get('team1.id')? and @get('team2.id')?
    ).property('tournament', 'round', 'team1', 'team2')

`export default Game`
