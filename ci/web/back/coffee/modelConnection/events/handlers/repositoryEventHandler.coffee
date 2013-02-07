assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new RepositoryEventHandler sockets


class RepositoryEventHandler extends EventHandler
	ROOM_PREFIX: 'repository-'
	EVENT_PREFIX: 'repository-'
	EVENT_NAMES: ['change added']


	processEvent: (data) =>
		roomName = @_getRoomName data.id, data.type
		eventName = @_getCompleteEventName data.id, data.type

		switch data.type
			when 'change added'
				@sockets.in(roomName).emit eventName,
					data.contents
			# when 'member added', 'member removed', 'member permissions changed'
			# 	@sockets.in(roomName).emit eventName,
			# 		type: data.type
			# 		contents: @_sanitizeUser data.contents
			# when 'forward url updated'
			# 	@sockets.in(roomName).emit eventName,
			# 		type: data.type
			# 		contents = @_sanitizeForwardUrlContents data.contents
			else
				throw new Error 'Unexpected event type: ' + data.type


	# _toPermissionString: (permissions) =>
	# 	switch permissions
	# 		when 1 then "r"
	# 		when 3 then "r/w"
	# 		when 7 then "r/w/a"
	# 		else ""
