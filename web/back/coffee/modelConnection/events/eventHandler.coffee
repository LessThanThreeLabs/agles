assert = require 'assert'


exports.create = (configurationParams, sockets) ->
	return new EventHandler configurationParams, sockets


class EventHandler
	constructor: (@configurationParams, @sockets) ->
		assert.ok @configurationParams? and @sockets?


	beginListening: () ->
		