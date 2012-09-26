fs = require 'fs'
assert = require 'assert'
redis = require 'socket.io/node_modules/redis'

RedisStore = require 'socket.io/lib/stores/redis'
Session = require('express').session.Session;


exports.create = (configurationParams, modelConnection, sessionStore) ->
	return new ResourceSocketConfigurer configurationParams, modelConnection, sessionStore


class ResourceSocketConfigurer
	constructor: (@configurationParams, @modelConnection, @sessionStore) ->
		assert.ok @configurationParams? and @modelConnection? and @sessionStore?


	configure: (socket) ->
		socket.configure () =>
			socket.set 'resource', '/socket'
			socket.set 'tranports', @configurationParams.socket.transports
			socket.enable 'browser client minification'
			socket.enable 'browser client etag'
			socket.enable 'browser client gzip'
			@_configureAuthorization socket
			# @_configureRedisStore socket
			@_configureModelEvents socket

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
			@sessionStore.get sessionId, (error, session) =>
				throw error if error?
				assert.ok session?

				# want to store this session as an express session 
				# so we get all those fancy methods in the future
				handshakeData.session = new Session {sessionID: sessionId, sessionStore: @sessionStore}, session

				if handshakeData.session.csrfToken != handshakeData.query.csrfToken
					callback 'Csrf token mismatch', false
				else
					callback null, true
		catch error
			callback 'Unable to retrieve session information', false
			throw error


	_getSessionIdFromCookie: (handshakeData) ->
		assert.ok handshakeData.headers.cookie?
		cookie = handshakeData.headers.cookie
		uriEncodedSessionId = cookie.substring @configurationParams.session.cookie.name.length + 1
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


	_configureModelEvents: (socket) ->
		@modelConnection.setSocketsToFireEventsOn socket.sockets


	configureConnection: (socket) ->
		socket.session = socket.handshake.session
		@_setupSessionMaintenance socket


	_setupSessionMaintenance: (socket) ->
		maintenanceInterval = setInterval (() ->
			socket.session.reload (error) ->
				throw error if error?
				socket.session.touch().save()
			), @configurationParams.socket.sessionRestoreInterval

		socket.on 'disconnect', () ->
			clearInterval maintenanceInterval
