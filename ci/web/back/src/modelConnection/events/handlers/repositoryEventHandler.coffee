assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new RepositoryEventHandler sockets


class RepositoryEventHandler extends EventHandler
	ROOM_PREFIX: 'repository-'
	EVENT_PREFIX: 'repository-'
	EVENT_NAMES: ['change added', 'change started', 'change finished']


	processEvent: (data) =>
		roomName = @_getRoomName data.id, data.type
		eventName = @_getCompleteEventName data.id, data.type

		switch data.type
			when 'change added'
				@sockets.in(roomName).emit eventName,
					id: data.contents.change_id
					number: data.contents.change_number
					status: data.contents.change_status
					submitter:
						email: 'jpotter@getkoality.com'
						firstName: 'Jordan'
						lastName: 'Potter'
			when 'change started', 'change finished'
				@sockets.in(roomName).emit eventName,
					id: data.contents.change_id
					status: data.contents.status
				# do nothing
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
