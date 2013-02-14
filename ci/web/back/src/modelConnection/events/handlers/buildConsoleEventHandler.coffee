assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new BuildConsolesEventHandler sockets


class BuildConsolesEventHandler extends EventHandler
	ROOM_PREFIX: 'buildConsole-'
	EVENT_PREFIX: 'buildConsole-'
	EVENT_NAMES: ['new output']


	processEvent: (data) =>
		roomName = @_getRoomName data.id, data.type
		eventName = @_getCompleteEventName data.id, data.type
		
		switch data.type
			when 'new output'
				@sockets.in(roomName).emit eventName,
					data.contents
			else
				throw new Error 'Unexpected event type: ' + data.type
