assert = require 'assert'
msgpack = require 'msgpack'


module.exports = class EventHandler
	constructor: (@sockets) ->
		assert.ok @sockets?


	handleEvent: (message, headers, deliveryInfo) =>
		# pass to child hnadler
		data = msgpack.unpack message
		@processEvent data
