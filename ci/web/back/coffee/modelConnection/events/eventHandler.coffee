assert = require 'assert'


exports.create = (configurationParams, connection) ->
	return new EventHandler configurationParams, connection


class EventHandler
	constructor: (@configurationParams, @connection) ->
		assert.ok @configurationParams? and @connection?


	connect: (callback) =>
		console.log 'need to connect to event framework in rabbitmq'
		callback()
		

	setSockets: (@sockets) =>
		assert.ok sockets
