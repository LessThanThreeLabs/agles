assert = require 'assert'

EventHandler = require './EventHandler'


exports.create = (sockets) ->
	return new BuildEventEventHandler sockets


class BuildEventEventHandler extends EventHandler

	registerForEvents: (socket, id) =>
		console.log 'need to register for build output events'


	processEvent: (message, headers, deliveryInfo) =>
		console.log 'need to handle build output event...'
