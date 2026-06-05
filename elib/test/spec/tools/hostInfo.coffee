_ = require 'underscore'
Promise = require 'bluebird'

describe('tools', ->
    describe('hostInfo', ->
        # require function
        hostInfo = require 'elib/tools/hostInfo'

        it('should resolve countries for ip addresses', ->
            # not testing if offline
            return @skip() if _.contains(TEST_ENV, 'offline')

            # init map
            map = [
                ['83.150.7.194', 'CH']
                ['5.9.53.30', 'DE']
                ['8.8.8.8', 'US']
            ]

            # swiss ip
            expect(Promise.each(map, (element) ->
                hostInfo(element[0]).then((hostInfo) ->
                    expect(hostInfo.country).to.equal element[1]
                )
            )).to.be.fulfilled
        )
    )
)