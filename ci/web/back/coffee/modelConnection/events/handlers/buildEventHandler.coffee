assert = require 'assert'

EventHandler = require './EventHandler'


exports.create = (sockets) ->
	return new BuildEventHandler sockets


class BuildEventHandler extends EventHandler

	registerForEvents: (socket, id) =>
		console.log 'need to register for events'


	processEvent: (message, headers, deliveryInfo) =>
		console.log 'need to handle build event...'
