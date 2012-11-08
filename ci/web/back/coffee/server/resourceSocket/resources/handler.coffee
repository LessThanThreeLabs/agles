assert = require 'assert'


module.exports = class Handler
	constructor: (@modelRpcConnection) ->
		assert.ok @modelRpcConnection?


	default: (socket, data, callback) ->
		callback 'subscribe not written yet' if callback?
