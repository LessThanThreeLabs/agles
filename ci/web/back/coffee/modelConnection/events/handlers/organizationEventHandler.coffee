assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new OrganizationEventHandler sockets


class OrganizationEventHandler extends EventHandler

	processEvent: (data) =>
		console.log 'need to handle organization event...'
