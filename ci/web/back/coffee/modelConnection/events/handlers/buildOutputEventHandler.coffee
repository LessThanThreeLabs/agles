assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new BuildOutputEventHandler sockets


class BuildOutputEventHandler extends EventHandler
	ROOM_PREFIX: 'buildOutput-'
	EVENT_PREFIX: 'buildOutput-'


	processEvent: (data) =>
		roomName = @ROOM_PREFIX + data.id
		eventName = @EVENT_PREFIX + data.id
		
		@sockets.in(roomName).emit eventName, 
			type: data.type
			contents: @_sanitizeContents data.contents


	_sanitizeContents: (data) =>
		number: data.line_num
		text: data.line