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
						email: data.contents.user.email
						firstName: data.contents.user.first_name
						lastName: data.contents.user.last_name
			when 'change started', 'change finished'
				@sockets.in(roomName).emit eventName,
					id: data.contents.change_id
					status: data.contents.status
					startTime: data.contents.start_time
					endTime: data.contents.end_time
			else
				throw new Error 'Unexpected event type: ' + data.type
				