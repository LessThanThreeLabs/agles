assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new BuildEventHandler sockets


class BuildEventHandler extends EventHandler
	ROOM_PREFIX: 'build-'
	EVENT_PREFIX: 'build-'


	processEvent: (data) =>
		console.log 'need to handle build event...'
