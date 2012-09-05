assert = require 'assert'
io = require 'socket.io'

Configurer = require './configuration'


exports.create = (configurationParams, sessionStore, modelConnection) ->
	configurer = Configurer.create configurationParams, sessionStore
	return new ResourceSocket configurer, modelConnection


class ResourceSocket
	constructor: (@configurer, @modelConnection) ->
		assert.ok @configurer? and @modelConnection?


	start: (server) ->
		@socketio = io.listen server
		@configurer.configure @socketio

		@socketio.sockets.on 'connection', (socket) ->
			socket.emit 'news', hello: 'world'
			socket.on 'my other event', (data) ->
				console.log 'data: ' + data