assert = require 'assert'
redis = require 'redis'
msgpack = require 'msgpack'


exports.create = (configurationParams) ->
	createRepositoryStore = new CreateRepositoryStore configurationParams
	createRepositoryStore.initialize()
	return createRepositoryStore


class CreateRepositoryStore
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	initialize: () ->
		@redisConnection = redis.createClient @configurationParams.redisStores.createRepository.port, 
			@configurationParams.redisStores.createRepository.url, return_buffers: true


	addRepository: (alias, repository) ->
		assert.ok alias? and repository?
		@redisConnection.set alias, msgpack.pack repository


	getRepository: (alias, callback) ->
		assert.ok alias?
		@redisConnection.get alias, (error, reply) ->
			if error? 
				callback error
			else if not reply? 
				callback 404
			else 
				callback null, msgpack.unpack reply


	removeRepository: (alias) ->
		assert.ok alias?
		@redisConnection.del alias, (error, numRemoved) ->
			console.error error if error?
			console.log 'createRepositoryStore - num removed: ' + numRemoved
