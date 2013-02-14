assert = require 'assert'


module.exports = class Handler
	constructor: (@modelRpcConnection) ->
		assert.ok @modelRpcConnection?
