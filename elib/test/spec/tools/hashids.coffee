_ = require 'underscore'

describe('tools', ->
    describe('hashids', ->
        # initialize hashids
        hashids = require('elib/tools/hashids')(
            default: 'b589bf003b594598a5e3b9f2a3af3a5c'
        )

        it('should encode a single id', ->
            hashed = hashids.hash 1, 'default'
            expect(hashed).to.equal 'g4qg4y'
        )

        ###
        # library does not support this
        it('should encode id arrays', ->
            hashed = hashids.hash '1,2,3', 'default'
            expect(hashed).to.deep.equal ['g4qg4y', 'z42r4p', '24gx37']
        )
        ###

        it('should decode a single id', ->
            decoded = hashids.decode 'g4qg4y', 'default'
            expect(decoded).to.equal 1
        )

        it('should decode id arrays', ->
            decoded = hashids.decode 'g4qg4y,z42r4p,24gx37', 'default'
            expect(decoded).to.deep.equal [1, 2, 3]
        )

        it('should decode special id', ->
            decoded = hashids.decode '84e683', 'default'
            expect(decoded).to.equal 49
        )
    )
)