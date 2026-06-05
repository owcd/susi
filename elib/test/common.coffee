chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'

chai.use(chaiAsPromised)
chai.should()

global.assert = chai.assert
global.chai = chai
global.expect = global.chai.expect