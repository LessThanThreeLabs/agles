assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new ChangeEventHandler sockets


class ChangeEventHandler extends EventHandler
	ROOM_PREFIX: 'change-'
	EVENT_PREFIX: 'change-'


	processEvent: (data) =>
		roomName = @ROOM_PREFIX + data.id
		eventName = @EVENT_PREFIX + data.id

		switch data.type
			when 'change started', 'change ended'
				console.log 'need to handle change started/ended...'
				@sockets.in(roomName).emit eventName,
					type: data.type
					contents: @_sanitizeChange data.contents
			else
				throw new Error 'Unexpected event type: ' + data.type


	_sanitizeChange: (data) =>
		status: data.status
		startTime: data.start_time
		endTime: data.end_time
