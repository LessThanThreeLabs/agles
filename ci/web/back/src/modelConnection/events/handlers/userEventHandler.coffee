assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new UserEventHandler sockets


class UserEventHandler extends EventHandler
	ROOM_PREFIX: 'user-'
	EVENT_PREFIX: 'user-'
	EVENT_NAMES: ['user created', 'user removed', 'user updated', 'ssh pubkey added', 'ssh pubkey removed', 'repo added', 'repo removed']

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
			when 'user created', 'user removed'
				console.error 'NEED TO HANDLE USER ADDED/REMOVED EVENTS'
			when 'repo added', 'repo removed'
				console.error 'NEED TO HANDLE REPOSITORY ADDED/REMOVED EVENTS'
			else
				throw new Error 'Unexpected event type: ' + data.type
