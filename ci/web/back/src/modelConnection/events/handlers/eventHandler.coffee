assert = require 'assert'
msgpack = require 'msgpack'


module.exports = class EventHandler
	
	constructor: (@sockets) ->
		assert.ok @sockets?


	registerForEvents: (socket, id, eventName) =>
		assert.ok @ROOM_PREFIX
		assert.ok socket?

		return null if typeof id isnt 'number'
		return null if typeof eventName isnt 'string'
		return null if eventName not in @EVENT_NAMES

		roomName = @_getRoomName id, eventName
		if socket.roomCounter[roomName]?
			socket.roomCounter[roomName]++
		else
			socket.roomCounter[roomName] = 1

		console.log 'adding to room: ' + roomName
		socket.join roomName if socket.roomCounter[roomName] > 0

		return @_getCompleteEventName id, eventName


	unregisterForEvents: (socket, id, eventName) =>
		assert.ok @ROOM_PREFIX
		assert.ok socket? 

		return false if typeof id isnt 'number'
		return false if typeof eventName isnt 'string'
		return false if eventName not in @EVENT_NAMES

		roomName = @_getRoomName id, eventName

		socket.roomCounter[roomName] = Math.max socket.roomCounter[roomName] - 1, 0
		console.log 'removing from room: ' + roomName
		socket.leave roomName if socket.roomCounter[roomName] is 0

		return true


	_getRoomName: (id, eventName) =>
		return @ROOM_PREFIX + id + ' | ' + eventName


	_getCompleteEventName: (id, eventName) =>
		return @EVENT_PREFIX + id + ' | ' + eventName


	handleEvent: (message, headers, deliveryInfo) =>
		# pass to child handler
		data = msgpack.unpack message.data
		@processEvent data

		console.log 'received event:'
		console.log data
