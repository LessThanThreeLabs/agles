assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new BuildOutputEventHandler sockets


class BuildOutputEventHandler extends EventHandler
	ROOM_PREFIX: 'buildOutput-'
	EVENT_PREFIX: 'buildOutput-'


	registerForEvents: (socket, id) =>
		assert.ok socket? and id? and typeof id is 'number'
		socket.join @ROOM_PREFIX + id

		setInterval (() =>
			data =
				id: id
				name: @EVENT_PREFIX + id
				contents:
					some: 'contents'
			@processEvent data
			), 10000

		return @EVENT_PREFIX + id


	unregisterForEvents: (socket, id) =>
		assert.ok socket? and id? and typeof id is 'number'
		socket.leave @ROOM_PREFIX + id


	processEvent: (data) =>
		console.log 'emitting... ' + data.name
		@sockets.in(@ROOM_PREFIX + data.id).emit data.name, data.contents
