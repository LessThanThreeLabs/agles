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
			console.log 'searching for session with id: ' + sessionId
			@sessionStore.get sessionId, (error, session) ->
				throw error if error?
				console.log 'failed to find session?' if not session?
				assert.ok session?

				# will need a deep copy of the session object for future use!!
				# ...right?  it has to be a deep copy? otherwise actions won't get pushed to redis??
				# socket.session = new Session {sessionStore: @sessionStore}, session
				socket.session = session

				console.log socket.session.csrfToken
				console.log '== ?'
				console.log handshakeData.query.csrfToken
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
		return cookie.substring 'connect.sid='.length
		# cookie = parseCookie handshakeData.headers.cookie
		# return cookie[@configurationParams.session.cookie.name]


	_configureRedisStore: (socket) ->
		socket.set 'store', new RedisStore
			url: @configurationParams.redis.url
			port: @configurationParams.redis.port
			redisClient: redis.createClient()
			redisPub: redis.createClient()
			redisSub: redis.createClient()
