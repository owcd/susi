md5 = require 'md5'

module.exports = (client, ns, ttl, f) ->
    # returns the function
    ->
        # define key based on the function arguments
        args = Array::slice.call arguments
        key = ns + ':' + md5(JSON.stringify(args))

        # load from cache
        client.get(key).then((data) ->
            if data
                JSON.parse data
            else
                f.apply(@, args).then((data) ->
                    # cache
                    client.setex(key, ttl, JSON.stringify(data)).then( ->
                        data
                    )
                )
        )