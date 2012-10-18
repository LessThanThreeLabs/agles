assert = require 'assert'
redis = require 'redis'
msgpack = require 'msgpack'


exports.create = (configurationParams) ->
	createAccountStore = new CreateAccountStore configurationParams
	createAccountStore.initialize()
	return createAccountStore


class CreateAccountStore
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	initialize: () ->
		@redisConnection = redis.createClient @configurationParams.port, @configurationParams.url, return_buffers: true


	addAccount: (key, account) ->
		assert.ok key? and account?
		@redisConnection.set key, msgpack.pack account


	getAccount: (key, callback) ->
		assert.ok key?
		@redisConnection.get key, (error, reply) ->
			if error? then callback error
			else callback null, msgpack.unpack reply


	removeAccount: (key) ->
		assert.ok key?
		@redisConnection.del key, (error, numRemoved) ->
			throw new Error error if error?
			console.log numRemoved
