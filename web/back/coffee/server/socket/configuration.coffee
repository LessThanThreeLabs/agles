fs = require 'fs'
redis = require 'socket.io/node_modules/redis'
redisStore = require 'socket.io/lib/stores/redis'


exports.configureSocket = (context, socket) ->
	socket.configure () ->
		socket.set 'resource', '/socket'
		socket.set 'transports', ['websocket', 'htmlfile', 'xhr-polling', 'jsonp-polling'] # 'flashsocket' won't send browser cookies
		socket.enable 'browser client minification'
		socket.enable 'browser client etag'
		socket.enable 'browser client gzip'
		configureOriginPolicy context, socket
		configureRedisStore context, socket

	socket.configure 'development', () ->
		socket.set 'log level', 2

	socket.configure 'production', () ->
		socket.set 'log level', 1


configureOriginPolicy = (context, socket) ->
	socket.set 'authorization', (handshakeData, callback) ->
		errorMessage = handshakeData.xdomain ? 'Cross domain sockets not allowed' : null
		callback errorMessage, !handshakeData.xdomain


configureRedisStore = (context, socket) ->
	socket.set 'store', new redisStore
		port: context.config.server.redis.port
		redisClient: redis.createClient()
		redisPub: redis.createClient()
		redisSub: redis.createClient()
