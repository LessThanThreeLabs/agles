fs = require 'fs'
redis = require 'socket.io/node_modules/redis'
redisStore = require 'socket.io/lib/stores/redis'


exports.configureSocket = (socket, serverConfiguration) ->
	socket.configure () ->
		socket.set 'resource', '/socket'
		socket.set 'transports', ['websocket', 'htmlfile', 'xhr-polling', 'jsonp-polling'] # 'flashsocket' won't send browser cookies
		socket.enable 'browser client minification'
		socket.enable 'browser client etag'
		socket.enable 'browser client gzip'
		configureOriginPolicy socket, serverConfiguration
		configureRedisStore socket, serverConfiguration

	socket.configure 'development', () ->
		socket.set 'log level', 2

	socket.configure 'production', () ->
		socket.set 'log level', 1


configureOriginPolicy = (socket, serverConfiguration) ->
	socket.set 'authorization', (handshakeData, callback) ->
		errorMessage = handshakeData.xdomain ? 'Cross domain sockets not allowed' : null
		callback errorMessage, !handshakeData.xdomain


configureRedisStore = (socket, serverConfiguration) ->
	socket.set 'store', new redisStore
		port: serverConfiguration.redis.port
		redisClient: redis.createClient()
		redisPub: redis.createClient()
		redisSub: redis.createClient()
