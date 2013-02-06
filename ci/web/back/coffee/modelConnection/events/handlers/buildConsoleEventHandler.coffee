assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new BuildConsolesEventHandler sockets


class BuildConsolesEventHandler extends EventHandler
	ROOM_PREFIX: 'buildConsole-'
	EVENT_PREFIX: 'buildConsole-'


	processEvent: (data) =>
		roomName = @ROOM_PREFIX + data.id
		eventName = @EVENT_PREFIX + data.id
		
		switch data.type
			when 'new output'
				@sockets.in(roomName).emit eventName,
					type: data.type
					contents: data.contents
			when 'return code added'
				@sockets.in(roomName).emit eventName,
					type: data.type
					contents: data.contents.return_code
			else
				throw new Error 'Unexpected event type: ' + data.type
