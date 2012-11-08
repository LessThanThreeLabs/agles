assert = require 'assert'


exports.create = (connection, exchange, routerName, queueName, handler) ->
	return new ResourceEventConnection connection, exchange, routerName, queueName, handler


class ResourceEventConnection
	constructor: (@connection, @exchange, @routerName, @queueName, @handler) ->
		assert.ok @connection? and @exchange? and @routerName? and @queueName? and @handler?


	connect: (callback) ->
		@connection.queue @queueName, {}, (@queue) =>
			queue.subscribe @handler.handleEvent
			queue.bind @exchange, @routerName

			callback()
