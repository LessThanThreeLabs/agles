assert = require 'assert'

EventHandler = require './EventHandler'


exports.create = (sockets) ->
	return new RepositoryEventHandler sockets


class RepositoryEventHandler extends EventHandler

	registerForEvents: (socket, id) =>
		console.log 'need to register for repository events'
		

	processEvent: (data) =>
		console.log 'need to handle repository event...'
