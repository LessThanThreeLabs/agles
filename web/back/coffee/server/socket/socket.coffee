fs = require 'fs'
socketio = require 'socket.io'
configurer = require './configuration'


exports.start = (server, serverConfiguration) ->
	io = socketio.listen server
	configurer.configureSocket io, serverConfiguration

	io.sockets.on 'connection', (socket) ->
		socket.emit 'news', hello: 'world'
		socket.on 'my other event', (data) ->
			console.log 'data: ' + data