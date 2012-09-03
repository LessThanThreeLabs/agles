fs = require 'fs'
assert = require 'assert'
redis = require 'socket.io/node_modules/redis'
redisStore = require 'socket.io/lib/stores/redis'


exports.create = (socketconfigurationParams, redisConfigurationParams) ->
	return new ResourceSocketConfigurer socketconfigurationParams, redisConfigurationParams


class ResourceSocketConfigurer
	constructor: (@socketconfigurationParams, @redisConfigurationParams) ->
		assert.ok @socketconfigurationParams? and @redisConfigurationParams?


	configure: (socket) ->
		socket.configure () =>
			socket.set 'resource', '/socket'
			socket.set 'tranports', @socketconfigurationParams.transports
			socket.enable 'browser client minification'
			socket.enable 'browser client etag'
			socket.enable 'browser client gzip'
			@_configureAuthorization socket
			@_configureRedisStore socket

		socket.configure 'development', () ->
			socket.set 'log level', 2

		socket.configure 'production', () ->
			socket.set 'log level', 1


	_configureAuthorization: (socket) ->
		socket.set 'authorization', (handshakeData, callback) ->
			errorMessage = handshakeData.xdomain ? 'Cross domain sockets not allowed' : null
			callback errorMessage, !handshakeData.xdomain


	_configureRedisStore: (socket) ->
		socket.set 'store', new redisStore
			url: @redisConfigurationParams.url
			port: @redisConfigurationParams.port
			redisClient: redis.createClient()
			redisPub: redis.createClient()
			redisSub: redis.createClient()
