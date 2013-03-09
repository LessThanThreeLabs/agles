assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new ChangeEventHandler sockets


class ChangeEventHandler extends EventHandler
	ROOM_PREFIX: 'change-'
	EVENT_PREFIX: 'change-'
	EVENT_NAMES: ['new build console', 'return code added']


	processEvent: (data) =>
		roomName = @_getRoomName data.id, data.type
		eventName = @_getCompleteEventName data.id, data.type

		switch data.type
			when 'new build console'
				@sockets.in(roomName).emit eventName,
					id: data.contents.id
					type: data.contents.type
					name: data.contents.subtype
					orderNumber: data.contents.subtype_priority
					status: @_returnCodeToStatus data.contents.return_code
			when 'return code added'
				@sockets.in(roomName).emit eventName,
					id: data.contents.build_console_id
					status: @_returnCodeToStatus data.contents.return_code
			else
				throw new Error 'Unexpected event type: ' + data.type


	_returnCodeToStatus: (returnCode) ->
		if not returnCode? then return 'running'
		else if returnCode is 0 then return 'passed'
		else return 'failed'