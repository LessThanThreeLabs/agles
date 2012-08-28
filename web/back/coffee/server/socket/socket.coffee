fs = require 'fs'
socketio = require 'socket.io'
configurer = require './configuration'


exports.start = (context, server) ->
	io = socketio.listen server
	configurer.configure context, io

	io.sockets.on 'connection', (socket) ->
		socket.emit 'news', hello: 'world'
		socket.on 'my other event', (data) ->
			console.log 'data: ' + data