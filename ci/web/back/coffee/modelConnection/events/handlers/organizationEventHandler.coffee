assert = require 'assert'

EventHandler = require './eventHandler'


exports.create = (sockets) ->
	return new OrganizationEventHandler sockets


class OrganizationEventHandler extends EventHandler
	ROOM_PREFIX: 'organization-'
	EVENT_PREFIX: 'organization-'


	processEvent: (data) =>
		console.log 'need to handle organization event...'
