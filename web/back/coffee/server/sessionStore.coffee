express = require 'express'

RedisStore = require('connect-redis')(express)


exports.create = (configurationParams) ->
	return new RedisStore
		url: configurationParams.redis.url
		port: configurationParams.redis.port