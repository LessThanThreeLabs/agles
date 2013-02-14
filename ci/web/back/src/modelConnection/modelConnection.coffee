assert = require 'assert'
amqp = require 'amqp'

RpcConnection = require './rpc/rpcConnection'
EventConnection = require './events/eventConnection'


exports.create = (configurationParams) ->
	return new ModelConnection configurationParams


class ModelConnection
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	connect: (callback) ->
		@connection = amqp.createConnection @configurationParams.messageBroker
		@connection.on 'ready', () =>
			@rpcConnection = RpcConnection.create @configurationParams, @connection
			@eventConnection = EventConnection.create @configurationParams, @connection
			
			await
				@rpcConnection.connect defer rpcConnectionError
				@eventConnection.connect defer eventConnectionError

			errors = (error for error in [rpcConnectionError, eventConnectionError] when error?)

			if errors.length is 0 
				callback()
			else 
				callback errors


		@connection.on 'error', (error) =>
			callback error


	setSocketsToFireEventsOn: (sockets, callback) ->
		@eventConnection.setSockets sockets, callback
		