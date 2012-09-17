assert = require 'assert'

ProxyHandler = require './proxyHandler'


exports.create = (configurationParams) ->
	return new RpcConnection configurationParams


class RpcConnection
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?

		@messageCount = 0
		@messageIdsToCallbacks = {}


	connect: (@connection, callback) ->
		assert.ok @connection? and callback?

		@connection.queue @configurationParams.rpc.queueName, (queue) ->
			@requestQueue = queue

			@connection.queue '', exclusive: true, (queue) ->
				@responseQueue = queue
				@responseQueue.subscribe @_handleResponse
				callback(null)


	callFunction: (functionName, args, callback) ->
		assert.ok functionName? and args? and callback?

		messageId = @_getNextMessageId()
		@messageIdsToCallbacks.messageId = callback

		@connection.publish @requestQueue, 'hello',
			replyTo: @responseQueue.name
			correlationId: messageId
			mandatory: true


	_handleResponse: (message, headers, deliveryInformation) ->
		console.log 'message came in... ' + message
		delete @messageIdsToCallbacks.deliveryInformation.correlationId


	_getNextMessageId: () ->
		id = @messageCount
		@messageCount++
		return id
