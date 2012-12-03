assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new OrganizationEventHandler sockets


class OrganizationEventHandler extends EventHandler

	registerForEvents: (socket, id) =>
		console.log 'need to register for organization events'


	processEvent: (data) =>
		console.log 'need to handle organization event...'
