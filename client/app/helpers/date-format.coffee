`import Ember from 'ember'`
`import moment from 'moment'`

dateFormat = (params, hash) ->
    value = params[0]
    str = ''
    if value != null
        # fmt arg?
        if hash.format
            fmt = hash.format
        else
            fmt = 'DD MMM YYYY'
        str = moment(value).format(fmt)

    # return
    Ember.String.htmlSafe str


DateFormatHelper = Ember.Helper.helper dateFormat

`export { dateFormat }`

`export default DateFormatHelper`
