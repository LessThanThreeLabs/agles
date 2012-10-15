express = require 'express'

RedisStore = require('connect-redis')(express)


exports.create = (configurationParams) ->
	return new RedisStore
		url: configurationParams.redis.sessionStore.url
		port: configurationParams.redis.sessionStore.port
		