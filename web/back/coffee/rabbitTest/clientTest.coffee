amqp = require 'amqp'

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
		console.log 'responseQueue received: ' + message.data

	deadLetterQueue.subscribe (message, headers, deliveryInformation) =>
		console.log 'deadLetterQueue received: ' + message.data

	startMakingRandomRequests exchange, responseQueue

startMakingRandomRequests = (exchange, responseQueue) ->
	setInterval (()-> makeRandomRequest exchange, responseQueue), 2000

makeRandomRequest = (exchange, responseQueue) ->
	message = Math.random().toString()
	exchange.publish 'builds-read', message,
		replyTo: responseQueue.name
		correlationId: Math.floor Math.random() * 10000
	console.log 'sent: ' + message
