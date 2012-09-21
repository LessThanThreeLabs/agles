assert = require 'assert'
msgpack = require 'msgpack'


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
		@connection.queue '', exclusive: true, (queue) =>
			@responseQueue = queue
			@responseQueue.subscribe @_handleResponse
			callback null


	callFunction: (route, functionName, args, callback) ->
		assert.ok route? and functionName? and args? and callback?

		messageId = @messageIdGenerator.generateUniqueId()
		@messageIdsToCallbacks[messageId] = callback

		message = msgpack.pack
			function: functionName
			args: args

		@exchange.publish route, message,
			replyTo: @responseQueue.name
			correlationId: messageId
			mandatory: true

		console.log 'sent: ' + JSON.stringify msgpack.unpack message


	_handleResponse: (message, headers, deliveryInformation) =>
		console.log 'received: ' + JSON.stringify msgpack.unpack message.data

		messageId = deliveryInformation.correlationId

		data = msgpack.unpack message.data
		error = if data.error? then new Error data.error else null
		returnValue = data.returnValue

		if not @messageIdsToCallbacks[messageId]?
			console.error 'Received unexpected rpc message ' + JSON.stringify response
		else
			callback = @messageIdsToCallbacks[messageId]
			delete @messageIdsToCallbacks[messageId]
			callback error, returnValue
