_ = require 'underscore'

describe('tools', ->
    describe('deepExtend', ->
        # require function
        deepExtend = require 'elib/tools/deepExtendClone'

        # define test objects
        objs = []
        for i in [1..3]
            objs[i - 1] =
                name: 'obj' + i
                subobj:
                    name: 'subobj' + i
            objs[i - 1]['obj' + i] = 'obj' + i
            objs[i - 1]['subobj']['subobj' + i] = 'subobj' + i
            objs[i - 1]['subobj' + i] = _.clone objs[i - 1]['subobj']

        it('should deep extend two objects', ->
            # final
            final = deepExtend objs[0], objs[1]

            # main elements
            expect(final.name).to.be.equal('obj2')
            expect(final.subobj.name).to.be.equal('subobj2')

            # elements
            for i in [1..2]
                expect(final['obj' + i]).to.be.equal('obj' + i)
                expect(final.subobj['subobj' + i]).to.be.equal('subobj' + i)
        )

        it('should deep extend three objects', ->
            # final
            final = deepExtend objs[0], objs[1], objs[2]

            # main elements
            expect(final.name).to.be.equal('obj3')
            expect(final.subobj.name).to.be.equal('subobj3')

            # elements
            for i in [1..3]
                expect(final['obj' + i]).to.be.equal('obj' + i)
                expect(final.subobj['subobj' + i]).to.be.equal('subobj' + i)
        )
    )
)