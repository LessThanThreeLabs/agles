assert = require 'assert'


exports.create = (rpcHandler) ->
	return new RpcHandlerFunctionProxy rpcHandler


class RpcHandlerFunctionProxy
	constructor: (@rpcHandler) ->
		assert.ok @rpcHandler?
		@proxy = Proxy.create @, @rpcHandler


	getProxy: () ->
		return @proxy


	get: (object, name) ->
		return (type, args..., callback) ->
			object.callFunction name, type, args, callback
