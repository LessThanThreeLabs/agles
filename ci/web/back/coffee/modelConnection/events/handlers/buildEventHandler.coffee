assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new BuildEventHandler sockets


class BuildEventHandler extends EventHandler

	registerForEvents: (socket, id) =>
		console.log 'need to register for events'


	processEvent: (data) =>
		console.log 'need to handle build event...'
