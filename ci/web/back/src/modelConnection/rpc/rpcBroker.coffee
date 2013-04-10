assert = require 'assert'
msgpack = require 'msgpack'
crypto = require 'crypto'


exports.create = (connection, exchange, deadLetterExchange, messageIdGenerator, logger) ->
	return new RpcBroker connection, exchange, deadLetterExchange, messageIdGenerator, logger


class RpcBroker
	constructor: (@connection, @exchange, @deadLetterExchange, @messageIdGenerator, @logger) ->
		assert.ok @connection?
		assert.ok @exchange?
		assert.ok @deadLetterExchange?
		assert.ok @messageIdGenerator?
		assert.ok @logger?

		@exchange.on 'basic-return', (args) ->
			if args.replyCode isnt 200
				logger.error "Message broker bad reply (#{args.replyCode}) - #{args.replyText}"

		# If someone makes this an array instead of an object
		# our servers will OOM and I'll punch a small duckling.
		# Seriously.
		@messageIdsToCallbacks = {}


	connect: (callback) ->
		await
			@connection.queue '', exclusive: true, defer @responseQueue
			@connection.queue '', exclusive: true, defer @deadLetterQueue

		@responseQueue.subscribe @_handleResponse

		@deadLetterQueue.subscribe @_handleDeadLetterResponse
		@deadLetterQueue.bind @deadLetterExchange, ''

		callback null


	callFunction: (route, methodName, args, callback) ->
		assert.ok route? and methodName? and args? and callback?

		messageId = @messageIdGenerator.generateUniqueId()
		@messageIdsToCallbacks[messageId] = callback

		message = msgpack.pack
			method: methodName
			args: args

		@exchange.publish route, message,
			contentType: 'application/x-msgpack'
			contentEncoding: 'binary'
			replyTo: @responseQueue.name
			correlationId: messageId
			mandatory: true

		@logger.debug 'rpcBroker | calling function: ' + route + ' > ' + methodName


	_handleResponse: (message, headers, deliveryInformation) =>
		messageId = deliveryInformation.correlationId
		data = msgpack.unpack message.data

		if not @messageIdsToCallbacks[messageId]?
			@logger.warn 'rpcBroker | received unexpected rpc message ' + JSON.stringify data
		else
			callback = @messageIdsToCallbacks[messageId]
			delete @messageIdsToCallbacks[messageId]

			if data.error?
				@logger.info 'rpcBroker | error in handle response: ' + JSON.stringify data.error 

			callback data.error, data.value


	_handleDeadLetterResponse: (message, headers, deliveryInformation) =>
		@logger.warn 'rpcBroker | received dead letter message: ' + JSON.stringify msgpack.unpack message.data

		responseQueueName = deliveryInformation.replyTo
		messageId = deliveryInformation.correlationId

		if responseQueueName is @responseQueue.name and @messageIdsToCallbacks[messageId]?
			callback = @messageIdsToCallbacks[messageId]
			delete @messageIdsToCallbacks[messageId]

			error = 
				type: 'TimedOutError'
				message: 'Message was dead-lettered: ' + JSON.stringify msgpack.unpack message.data
			callback error, null
