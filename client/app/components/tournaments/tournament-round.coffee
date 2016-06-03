`import Ember from 'ember'`
`import moment from 'moment'`

TournamentsTournamentRoundComponent = Ember.Component.extend
    store: Ember.inject.service 'store'
    classNames: ['row', 'tournament-round']
    modify: false
    start: null
    end: null

    isModify: ( ->
        not @get('round.id')? or @get('modify')
    ).property('round.id', 'modify')

    courtsColumns: ( ->
        Math.floor(12 / @get('courts.length'))
    ).property('courts')

    games: ( ->
        @get('courts').map (court) =>
            game = @get('round.games').findBy 'court.id', court.get('id')
            if not game?
                game = @get('store').createRecord 'game',
                    court: court
                    round: @get('round')
                @get('round.games').pushObject game
            game
    ).property('courts', 'round.games')

    updateStartAndEndDate: ( ->
        ['start', 'end'].forEach (field) =>
            date = @get('round').get(field)
            date = moment(date).format('HH:mm') if date?
            @set field, date
    ).observes('round.start', 'round.end').on('init')

    actions:
        save: ->
            # store start and end date
            properties = {}
            ['start', 'end'].forEach (field) =>
                properties[field] = null
                time = moment(@get(field), 'HH:mm')
                if time? and time.isValid()
                    date = moment(@get('round.tournament.date')).format('YYYY-MM-DD')
                    #date = moment().format('YYYY-MM-DD')
                    timestamp = moment(date + ' ' + @get(field), 'YYYY-MM-DD HH:mm')
                    properties[field] = timestamp

            # set the properties
            @get('round').setProperties properties

            # disable modify and save
            @set 'modify', false
            @get('round').save().then( =>
                Ember.RSVP.all @get('games').map((game) =>
                    if game.get('isPlayable')
                        game.save()
                    else if not game.get('isNew')
                        game.destroyRecord()
                )
            )

        modify: ->
            @set 'modify', true

        remove: ->
            Ember.RSVP.all(@get('games').map((game) =>
                game.destroyRecord() unless game.get('isNew')
            )).then( =>
                @get('round').destroyRecord()
            )

`export default TournamentsTournamentRoundComponent`
