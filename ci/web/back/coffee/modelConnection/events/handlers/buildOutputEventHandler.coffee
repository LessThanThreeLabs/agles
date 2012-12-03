assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new BuildOutputEventHandler sockets


class BuildOutputEventHandler extends EventHandler
	ROOM_PREFIX: 'buildOutput-'
	EVENT_PREFIX: 'buildOutput-'


	registerForEvents: (socket, id) =>
		assert.ok socket? and id? and typeof id is 'number'
		socket.join @ROOM_PREFIX + id
		return @EVENT_PREFIX + id


	unregisterForEvents: (socket, id) =>
		assert.ok socket? and id? and typeof id is 'number'
		socket.leave @ROOM_PREFIX + id


	processEvent: (data) =>
		roomName = @ROOM_PREFIX + data.id
		eventName = @EVENT_PREFIX + data.id
		eventType = data.name
		
		@sockets.in(roomName).emit eventName, 
			type: eventType
			contents: @_sanitizeContents data.contents


	_sanitizeContents: (data) =>
		number: data.line_num
		text: data.line