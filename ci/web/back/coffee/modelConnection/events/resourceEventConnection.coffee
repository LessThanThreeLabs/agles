assert = require 'assert'


exports.create = (connection, exchange, routeName, queueName, handler) ->
	return new ResourceEventConnection connection, exchange, routeName, queueName, handler


class ResourceEventConnection
	constructor: (@connection, @exchange, @routeName, @queueName, @handler) ->
		assert.ok @connection? and @exchange? and @routeName? and @queueName? and @handler?


	connect: (callback) ->
		@connection.queue @queueName, {}, (@queue) =>
			queue.subscribe @handler.handleEvent
			queue.bind @exchange, @routeName

			callback()
