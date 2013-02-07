assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new UserEventHandler sockets


class UserEventHandler extends EventHandler
	ROOM_PREFIX: 'user-'
	EVENT_PREFIX: 'user-'
	eventNames: ['user updated']

	processEvent: (data) =>
		assert.ok data.type in @eventNames

		roomName = @_getRoomName data.id, data.type
		eventName = @_getCompleteEventName data.id, data.type

		switch data.type
			when 'user updated'
				@sockets.in(roomName).emit eventName,
					firstName: data.contents.first_name
					lastName: data.contents.last_name
			when 'ssh pubkey added', 'ssh pubkey removed'
				@sockets.in(roomName).emit eventName,
					type: data.type
					contents: @_sanitizeSshKey data.contents
			else
				throw new Error 'Unexpected event type: ' + data.type


	_sanitizeSshKey: (data) =>
		alias: data.alias
		dateAdded: 'need a real timestamp here...'
