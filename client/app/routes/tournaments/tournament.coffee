`import Ember from 'ember'`

TournamentsTournamentRoute = Ember.Route.extend
    model: (params) ->
        @store.queryRecord('tournament',
            filter:
                id: params.tournament_id
            include: ['courts', 'groups']
            groups:
                include: 'teams'
                sort: 'name'
                teams:
                    sort: 'number'
        ).then((tournament) =>
            tournament = tournament.get('firstObject')
            @store.query('round',
                filter:
                    tournament_id: tournament.get('id')
                include: 'games'
                games:
                    include: ['team1', 'team2']
                sort: 'start'
            ).then((rounds) =>
                tournament.set 'rounds', rounds
                tournament
            )
        )

`export default TournamentsTournamentRoute`