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
			@eventHandler = EventHandler.create @configurationParams, @connection
			
			await
				@rpcConnection.connect defer rpcConnectionError
				@eventHandler.connect defer eventHandlerError

			if rpcConnectionError?
				callback rpcConnectionError
			else if eventHandlerError?
				callback eventHandlerError
			else
				callback null

		@connection.on 'error', (error) =>
			callback error


	setSocketsToFireEventsOn: (sockets) ->
		@eventHandler.setSockets sockets
		