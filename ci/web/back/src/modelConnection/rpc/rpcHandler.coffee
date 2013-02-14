assert = require 'assert'


exports.create = (route, rpcBroker) ->
	return new RpcHandler route, rpcBroker


class RpcHandler
	constructor: (@route, @rpcBroker) ->
		assert.ok @route? and @rpcBroker?


	callFunction: (functionName, args, callback) ->
		@rpcBroker.callFunction @route, functionName, args, callback
		