assert = require 'assert'
io = require 'socket.io'

Configurer = require './configuration'
ResourceRouter = require './resourceRouter'


exports.create = (configurationParams, sessionStore, modelConnection) ->
	configurer = Configurer.create configurationParams, modelConnection, sessionStore
	resourceRouter = ResourceRouter.create configurationParams, modelConnection.rpcConnection
	return new ResourceSocket configurer, resourceRouter


class ResourceSocket
	constructor: (@configurer, @resourceRouter) ->
		assert.ok @configurer? and @resourceRouter?


	start: (server) ->
		@socketio = io.listen server
		@configurer.configure @socketio

		@socketio.sockets.on 'connection', (socket) =>
			@configurer.configureConnection socket
			@resourceRouter.bindToResources socket

			socket.emit 'news', hello: 'world'
			socket.on 'my other event', (data) ->
				console.log 'data: ' + data
