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
			when 'member added', 'member removed', 'member permissions changed'
				@sockets.in(roomName).emit eventName,
					type: data.type
					contents: @_sanitizeUser data.contents
			when 'description updated'
				@sockets.in(roomName).emit eventName,
					type: data.type
					contents = data.contents
			else
				throw new Error 'Unexpected event type: ' + data.type


	_sanitizeChangeAddedContents: (data) =>
		id: data.change_id
		number: data.change_number
		status: data.change_status


	_sanitizeUser: (user) =>
		id: user.id
		firstName: user.first_name
		lastName: user.last_name
		email: user.email
		permissions: @_toPermissionString user.permissions


	_toPermissionString: (permissions) =>
		switch permissions
			when 1 then "r"
			when 3 then "r/w"
			when 7 then "r/w/a"
			else ""
