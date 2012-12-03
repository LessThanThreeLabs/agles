assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new BuildOutputEventHandler sockets


class BuildOutputEventHandler extends EventHandler

	registerForEvents: (socket, id) =>
		console.log 'need to register for build output events'


	processEvent: (data) =>
		console.log 'need to handle build output event...'
