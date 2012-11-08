assert = require 'assert'

EventHandler = require './EventHandler'


exports.create = (sockets) ->
	return new OrganizationEventEventHandler sockets


class OrganizationEventEventHandler extends EventHandler

	registerForEvents: (socket, id) =>
		console.log 'need to register for organization events'


	processEvent: (message, headers, deliveryInfo) =>
		console.log 'need to handle organization event...'
