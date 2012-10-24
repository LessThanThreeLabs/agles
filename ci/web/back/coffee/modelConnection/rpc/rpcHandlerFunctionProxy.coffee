assert = require 'assert'


exports.create = (rpcHandler) ->
	handler = new Handler rpcHandler
	return Proxy.create handler


class Handler
	constructor: (@rpcHandler) ->
		assert.ok @rpcHandler?


	get: (proxy, name) ->
		return (args..., callback) =>
			@rpcHandler.callFunction name, args, callback
			