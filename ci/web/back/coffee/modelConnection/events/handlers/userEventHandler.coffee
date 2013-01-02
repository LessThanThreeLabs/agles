assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new UserEventHandler sockets


class UserEventHandler extends EventHandler
	ROOM_PREFIX: 'user-'
	EVENT_PREFIX: 'user-'


	processEvent: (data) =>
		roomName = @ROOM_PREFIX + data.id
		eventName = @EVENT_PREFIX + data.id

		switch data.type
			when 'user updated'
				console.log 'need to handle user updated event...'
			when 'ssh pubkey added', 'ssh pubkey removed'
				@sockets.in(roomName).emit eventName,
					type: data.type
					contents: @_sanitizeSshKey data.contents
			else
				throw new Error 'Unexpected event type: ' + data.type

	_sanitizeSshKey: (data) =>
		id: data.id
		alias: data.alias
		dateAdded: 'need a real timestamp here...'
