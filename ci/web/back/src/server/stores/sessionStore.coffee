express = require 'express'

RedisStore = require('connect-redis')(express)


exports.create = (configurationParams) ->
	return new RedisStore
		url: configurationParams.redisStores.session.url
		port: configurationParams.redisStores.session.port
		