amqp = require 'amqp'
msgpack = require 'msgpack'


connection = amqp.createConnection()
connection.on 'ready', () ->
	await
		connection.exchange 'model-rpc', type: 'direct', defer exchange
		connection.exchange 'model-rpc-deadLetter', type: 'fanout', defer deadLetterExchange

	await
		connection.queue '', exclusive: true, defer responseQueue
		connection.queue '', exclusive: true, defer deadLetterQueue

	deadLetterQueue.bind deadLetterExchange, ''

	responseQueue.subscribe (message, headers, deliveryInformation) =>
		console.log 'responseQueue received: ' + JSON.stringify msgpack.unpack message.data

	deadLetterQueue.subscribe (message, headers, deliveryInformation) =>
		console.log 'deadLetterQueue received: ' + JSON.stringify msgpack.unpack message.data

	startMakingRandomRequests exchange, responseQueue


startMakingRandomRequests = (exchange, responseQueue) ->
	setInterval (()-> makeRandomRequest exchange, responseQueue), 2000


makeRandomRequest = (exchange, responseQueue) ->
	message = msgpack.pack
		function: 'foo'
		args: [Math.random().toString(), Math.random().toString()]

	fromId = (Math.floor Math.random() * 10000).toString()
	messageId = (Math.floor Math.random() * 10000).toString()

	exchange.publish 'builds-read', message,
		replyTo: responseQueue.name
		correlationId: messageId
		headers:
			from: fromId

	console.log 'sent: ' + JSON.stringify msgpack.unpack message
