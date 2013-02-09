assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new BuildConsolesEventHandler sockets


class BuildConsolesEventHandler extends EventHandler
	ROOM_PREFIX: 'buildConsole-'
	EVENT_PREFIX: 'buildConsole-'
	EVENT_NAMES: ['new output', 'return code added']


	processEvent: (data) =>
		roomName = @_getRoomName data.id, data.type
		eventName = @_getCompleteEventName data.id, data.type
		
		switch data.type
			when 'new output'
				@sockets.in(roomName).emit eventName,
					data.contents
			when 'return code added'
				console.log 'return code added'
				# @sockets.in(roomName).emit eventName,
				# 	type: data.type
				# 	contents: data.contents.return_code
			else
				throw new Error 'Unexpected event type: ' + data.type
