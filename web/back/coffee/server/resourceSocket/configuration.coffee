fs = require 'fs'
assert = require 'assert'
redis = require 'socket.io/node_modules/redis'
redisStore = require 'socket.io/lib/stores/redis'

Session = require('express').session.Session;


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
		socket.set 'authorization', (handshakeData, callback) =>
			if handshakeData.xdomain
				callback 'Cross domain sockets not allowed', false
				return

#			@_attachSessionToHandshake handshakeData
#			if not handshakeData.session?
#				callback 'Unable to retrieve session information', false
#			else if handshakeData.session.csrfToken != handshakeData.queryString.csrfToken
#				callback 'Csrf token mismatch', false
			else
				callback null, true


	_attachSessionToHandshake: (handshakeData) ->
		if handshakeData.headers.cookie?
			handshakeData.cookie = parseCookie handshakeData.headers.cookie
			return if not handshakeData.cookie['connect.sid']?

			handshakeData.sessionId = handshakeData.cookie['connect.sid']
			console.log 'sessionId: ' + handshakeData.sessionId

			handshakeData.sessionStore = redisStore
			console.log 'sessionStore: ' + handshakeData.sessionStore

			redisStore.get sessionId, (error, session) ->
				console.log 'error: ' + error
				console.log 'session: ' + session
				if not error? and session?
					handshakeData.session = new Session handshakeData, session
		else
			console.log 'blah1'

		console.log ' -------------------------- '


	_configureRedisStore: (socket) ->
		socket.set 'store', new redisStore
			url: @redisConfigurationParams.url
			port: @redisConfigurationParams.port
			redisClient: redis.createClient()
			redisPub: redis.createClient()
			redisSub: redis.createClient()
