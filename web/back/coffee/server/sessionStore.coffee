express = require 'express'

RedisStore = require('connect-redis')(express)


exports.create = (configurationParams) ->
	return new RedisStore
		url: configurationParams.session.redisStore.url
		port: configurationParams.session.redisStore.port
		