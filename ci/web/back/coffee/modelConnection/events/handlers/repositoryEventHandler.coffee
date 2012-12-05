assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new RepositoryEventHandler sockets


class RepositoryEventHandler extends EventHandler
	ROOM_PREFIX: 'repository-'
	EVENT_PREFIX: 'repository-'


	processEvent: (data) =>
		roomName = @ROOM_PREFIX + data.id
		eventName = @EVENT_PREFIX + data.id

		switch data.type
			when 'change added'
				@sockets.in(roomName).emit eventName, 
					type: data.type
					contents: @_sanitizeChangeAddedContents data.contents
			else
				throw new Error 'Unexpected event type: ' + data.type


	_sanitizeChangeAddedContents: (data) =>
		id: data.change_id
		number: data.change_number
