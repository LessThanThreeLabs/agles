assert = require 'assert'
amqp = require 'amqp'

EventHandler = require './events/eventHandler'
RpcConnection = require './rpc/rpcConnection'


exports.create = (configurationParams) ->
	return new ModelConnection configurationParams


class ModelConnection
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	connect: (callback) ->
		@connection = amqp.createConnection @configurationParams.messageBroker
		@connection.on 'ready', () =>
			@rpcConnection = RpcConnection.create @configurationParams, @connection
			@rpcConnection.connect callback
		@connection.on 'error', (error) =>
			callback error


	setSocketsToFireEventsOn: (sockets) ->
		assert.ok sockets?
		@eventHandler = EventHandler.create @configurationParams, sockets
		@eventHandler.beginListening()
		