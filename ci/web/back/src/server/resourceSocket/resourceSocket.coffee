assert = require 'assert'
io = require 'socket.io'

Configurer = require './configuration'
ResourceRouter = require './resourceRouter'


exports.create = (configurationParams, stores, modelConnection, mailer, logger) ->
	configurer = Configurer.create configurationParams, modelConnection, stores.sessionStore
	resourceRouter = ResourceRouter.create configurationParams, stores, modelConnection, mailer
	return new ResourceSocket configurer, resourceRouter


class ResourceSocket
	constructor: (@configurer, @resourceRouter) ->
		assert.ok @configurer?
		assert.ok @resourceRouter?


	start: (server) ->
		@socketio = io.listen server
		@configurer.configure @socketio

		@socketio.sockets.on 'connection', (socket) =>
			@configurer.configureConnection socket
			@resourceRouter.bindToResources socket
