amqp = require 'amqp'
msgpack = require 'msgpack'


connection = amqp.createConnection()
connection.on 'ready', () =>
	await
		connection.exchange 'model-rpc', type: 'direct', defer exchange
		connection.exchange 'model-rpc-deadLetter', type: 'fanout', defer deadLetterExchange

	queueArguments = 
		'x-message-ttl': 2000
		'x-dead-letter-exchange': 'model-rpc-deadLetter'

	await 
		connection.queue 'rpc:builds-read', arguments: queueArguments, defer queue

	queue.bind exchange, 'builds-read'

	queue.subscribe ack: true, (message, headers, deliveryInformation) ->
		console.log 'received: ' + JSON.stringify msgpack.unpack message.data

		toReturn = msgpack.pack
			error: null
			value: Math.random()
		connection.publish deliveryInformation.replyTo, toReturn,
			correlationId: deliveryInformation.correlationId
			headers:
				from: headers.from

		console.log 'sent: ' + JSON.stringify msgpack.unpack toReturn
		queue.shift() # IF YOU WANT TO TEST DEADLETTER, COMMENT OUT THIS LINE
