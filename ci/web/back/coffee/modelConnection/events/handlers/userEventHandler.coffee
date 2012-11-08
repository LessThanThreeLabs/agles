assert = require 'assert'

EventHandler = require './EventHandler'


exports.create = (sockets) ->
	return new UserEventHandler sockets


class UserEventHandler extends EventHandler

	registerForEvents: (socket, id) =>
		console.log 'need to register for user events'


	processEvent: (data) =>
		console.log 'need to handle user event...'
