assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new UserEventHandler sockets


class UserEventHandler extends EventHandler
	ROOM_PREFIX: 'user-'
	EVENT_PREFIX: 'user-'
	EVENT_NAMES: ['user added', 'user removed', 'user updated', 'ssh pubkey added', 'ssh pubkey removed', 'repository added', 'repository removed']

	processEvent: (data) =>
		roomName = @_getRoomName data.id, data.type
		eventName = @_getCompleteEventName data.id, data.type

		switch data.type
			when 'user updated'
				@sockets.in(roomName).emit eventName,
					firstName: data.contents.first_name
					lastName: data.contents.last_name
			when 'ssh pubkey added', 'ssh pubkey removed'
				@sockets.in(roomName).emit eventName,
					id: data.contents.id
					alias: data.contents.alias
					timestamp: data.contents.timestamp
			else
				throw new Error 'Unexpected event type: ' + data.type
