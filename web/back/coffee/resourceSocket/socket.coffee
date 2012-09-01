fs = require 'fs'
assert = require 'assert'
io = require 'socket.io'
socketConfigurer = require './configuration'


exports.create = (configuration, modelConnection) ->
	return new ResourceSocket configuration, modelConnection


class ResourceSocket
	constructor: (@configuration, modelConnection) ->
		assert.ok @configuration? and @modelConnection?


	start: (server) ->
		@socketio = io.listen server
		socketConfigurer.configure @socketio, @configuration

		@socketio.sockets.on 'connection', (socket) ->
			socket.emit 'news', hello: 'world'
			socket.on 'my other event', (data) ->
				console.log 'data: ' + data