assert = require 'assert'
msgpack = require 'msgpack'


module.exports = class EventHandler
	
	constructor: (@sockets) ->
		assert.ok @sockets?


	registerForEvents: (socket, id) =>
		assert.ok socket? and id? and typeof id is 'number'
		roomName = @ROOM_PREFIX + id
		
		if socket.roomCounter[roomName]?
			socket.roomCounter[roomName]++
		else
			socket.roomCounter[roomName] = 1

		socket.join roomName if socket.roomCounter[roomName] > 0
		return @EVENT_PREFIX + id


	unregisterForEvents: (socket, id) =>
		assert.ok socket? and id? and typeof id is 'number'
		roomName = @ROOM_PREFIX + id

		socket.roomCounter[roomName] = Math.max socket.roomCounter[roomName] - 1, 0
		socket.leave roomName if socket.roomCounter[roomName] is 0


	handleEvent: (message, headers, deliveryInfo) =>
		# pass to child handler
		data = msgpack.unpack message.data
		@processEvent data
