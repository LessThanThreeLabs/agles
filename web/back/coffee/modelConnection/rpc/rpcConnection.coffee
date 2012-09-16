assert = require 'assert'

ProxyHandler = require './proxyHandler'


exports.create = (configurationParams) ->
	return new RpcConnection configurationParams


class RpcConnection
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?

		@proxyHandler = ProxyHandler.create @configurationParams
		@proxy = Proxy.create @proxyHandler
