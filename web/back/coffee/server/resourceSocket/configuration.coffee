fs = require 'fs'
assert = require 'assert'
redis = require 'socket.io/node_modules/redis'

RedisStore = require 'socket.io/lib/stores/redis'
Session = require('express').session.Session;


exports.create = (configurationParams, sessionStore) ->
	return new ResourceSocketConfigurer configurationParams, sessionStore


class ResourceSocketConfigurer
	constructor: (@configurationParams, @sessionStore) ->
		assert.ok @configurationParams? and @sessionStore?


	configure: (socket) ->
		socket.configure () =>
			socket.set 'resource', '/socket'
			socket.set 'tranports', @configurationParams.socket.transports
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
			# TODO: do we need to check if secure here?
			if handshakeData.xdomain
				callback 'Cross domain sockets not allowed', false
			else
				@_handleSessionAuthorization socket, handshakeData, callback


	_handleSessionAuthorization: (socket, handshakeData, callback) ->
		try
			sessionId = @_getSessionIdFromCookie handshakeData
			@sessionStore.get sessionId, (error, session) ->
				throw error if error?
				assert.ok session?

				# want to store this session as an express session 
				# so we get all those fancy methods in the future
				socket.session = new Session {sessionID: sessionId, sessionStore: @sessionStore}, session
				console.log 'NEED TO TOUCH THE SESSION OBJECT EVERY ONCE IN A WHILE'

				if socket.session.csrfToken != handshakeData.query.csrfToken
					callback 'Csrf token mismatch', false
				else
					callback null, true
		catch error
			callback 'Unable to retrieve session information', false
			throw error


	_getSessionIdFromCookie: (handshakeData) ->
		assert.ok handshakeData.headers.cookie?
		cookie = handshakeData.headers.cookie
		uriEncodedSessionId = cookie.substring 'connect.sid='.length
		return decodeURIComponent uriEncodedSessionId
		# cookie = parseCookie handshakeData.headers.cookie
		# return cookie[@configurationParams.session.cookie.name]


	_configureRedisStore: (socket) ->
		socket.set 'store', new RedisStore
			url: @configurationParams.redis.url
			port: @configurationParams.redis.port
			redisClient: redis.createClient()
			redisPub: redis.createClient()
			redisSub: redis.createClient()
