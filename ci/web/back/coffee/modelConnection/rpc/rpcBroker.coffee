assert = require 'assert'
msgpack = require 'msgpack'
crypto = require 'crypto'


exports.create = (connection, exchange, deadLetterExchange, messageIdGenerator) ->
	return new RpcBroker connection, exchange, deadLetterExchange, messageIdGenerator


class RpcBroker
	constructor: (@connection, @exchange, @deadLetterExchange, @messageIdGenerator) ->
		assert.ok @connection? and @exchange? and @deadLetterExchange? and @messageIdGenerator?
		@exchange.on 'basic-return', (args) ->
			throw new Error 'Message broker - ' + args.replyText if args.replyCode != 200

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

		console.log '-- calling function: ' + route + ' > ' + methodName
		# console.log 'sent: ' + JSON.stringify msgpack.unpack message


	_handleResponse: (message, headers, deliveryInformation) =>
		# console.log 'received: ' + JSON.stringify msgpack.unpack message.data

		messageId = deliveryInformation.correlationId
		data = msgpack.unpack message.data

		if not @messageIdsToCallbacks[messageId]?
			console.error 'Received unexpected rpc message ' + JSON.stringify data
		else
			callback = @messageIdsToCallbacks[messageId]
			delete @messageIdsToCallbacks[messageId]

			error = data.error
			callback error, data.value


	_handleDeadLetterResponse: (message, headers, deliveryInformation) =>
		console.log 'received dead letter message!! ' + JSON.stringify msgpack.unpack message.data

		responseQueueName = deliveryInformation.replyTo
		messageId = deliveryInformation.correlationId

		if responseQueueName is @responseQueue.name and @messageIdsToCallbacks[messageId]?
			callback = @messageIdsToCallbacks[messageId]
			delete @messageIdsToCallbacks[messageId]

			error = new Error 'Rpc request timed out'
			callback error, null
