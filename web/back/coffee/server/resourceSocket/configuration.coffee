fs = require 'fs'
assert = require 'assert'
redis = require 'socket.io/node_modules/redis'
redisStore = require 'socket.io/lib/stores/redis'

Session = require('express').session.Session;


exports.create = (socketconfigurationParams, redisConfigurationParams, sessionConfigurationParams) ->
	return new ResourceSocketConfigurer socketconfigurationParams, redisConfigurationParams, sessionConfigurationParams


class ResourceSocketConfigurer
	constructor: (@socketconfigurationParams, @redisConfigurationParams, @sessionConfigurationParams) ->
		assert.ok @socketconfigurationParams? and @redisConfigurationParams? and @sessionConfigurationParams


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

# TODO: uncomment below when parseCookie is included in express!!
#			try
#				session = @_getSessionFromSessionId @_getSessionIdFromCookie handshakeData
				# will need a deep copy of the session object for future use!!
				# ...right?  it has to be a deep copy? otherwise actions won't get pushed to redis??
#				soctet.session = new Session {sessionStore: redisStore}, session
#			catch error
#				callback 'Unable to retrieve session information', false
#				throw error

#			if handshakeData.session.csrfToken != handshakeData.queryString.csrfToken
#				callback 'Csrf token mismatch', false
#				return

			callback null, true


	_getSessionIdFromCookie: (handshakeData) ->
		assert.ok handshakeData.headers.cookie?
		cookie = parseCookie handshakeData.headers.cookie
		return cookie[@sessionConfigurationParams.cookie.name]


	_getSessionFromSessionId: (sessionId) ->
		assert.ok sessionId?
		redisStore.get sessionId, (error, session) ->
			throw error if error?
			return session


	_configureRedisStore: (socket) ->
		socket.set 'store', new redisStore
			url: @redisConfigurationParams.url
			port: @redisConfigurationParams.port
			redisClient: redis.createClient()
			redisPub: redis.createClient()
			redisSub: redis.createClient()
