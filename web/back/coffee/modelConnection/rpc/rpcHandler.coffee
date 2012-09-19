assert = require 'assert'
msgpack = require 'msgpack'


exports.create = (connection, exchange, routeType, messageIdGenerator) ->
	return new RpcHandler connection, exchange, routeType, messageIdGenerator


class RpcHandler
	constructor: (@connection, @exchange, @routeType, @messageIdGenerator) ->
		assert.ok @connection? and @exchange? and @routeType? and @messageIdGenerator?
		@messageIdsToCallbacks = {}


	connect: (callback) ->
		@connection.queue '', exclusive: true, (queue) =>
			@responseQueue = queue
			@responseQueue.subscribe @_handleResponse
			callback null


	callFunction: (functionName, functionType, args, callback) ->
		assert.ok functionName? and functionType? and args? and callback?

		@messageIdGenerator.generateUniqueId (error, messageId) =>
			if error?
				callback error
			else 
				@_makeRequest messageId, functionName, functionType, args, callback


	_makeRequest: (messageId, functionName, functionType, args, callback) ->
		@messageIdsToCallbacks.messageId = callback

		route = @routeType + '.' + functionType
		message = msgpack.pack
			function: functionName
			args = args

		@exchange.publish route, message
			replyTo: @responseQueue.name
			correlationId: messageId
			mandatory: true

		console.log 'published message! ' + msgpack.unpack message


	_handleResponse: (message, headers, deliveryInformation) ->
		console.log 'message came in... ' + msgpack.unpack message

		messageId = deliveryInformation.correlationId
		delete @messageIdsToCallbacks.messageId
