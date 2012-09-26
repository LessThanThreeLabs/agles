assert = require 'assert'
amqp = require 'amqp'

EventHandler = require './events/eventHandler'
RpcConnection = require './rpc/rpcConnection'


exports.create = (configurationParams) ->
	return new ModelConnection configurationParams


class ModelConnection
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	connect: (callback) ->
		@connection = amqp.createConnection @configurationParams.messageBroker
		@connection.on 'ready', () =>
			@rpcConnection = RpcConnection.create @configurationParams, @connection
			@rpcConnection.connect callback

			# @_startFakeRpcMessages()
		@connection.on 'error', (error) =>
			callback error


	# _startFakeRpcMessages: () ->
	# 	setInterval (() =>
	# 		console.log '>> making rpc call'
	# 		@rpcConnection.builds.read.blah 'a', 'b', (error, data) ->
	# 			throw error if error?
	# 			console.log '>> result of rpc call: ' + data + '\n'
	# 		), 2000


	setSocketsToFireEventsOn: (sockets) ->
		assert.ok sockets?
		@eventHandler = EventHandler.create @configurationParams, sockets
		@eventHandler.beginListening()












	# getBuild: (user, repositoryId, buildId, callback) ->
	# 	assert.ok user? and repositoryId? and buildId? and callback?
	# 	build = @_createFakeBuild buildId, null
	# 	callback null, build


	# getBuilds: (user, repositoryId, startIndex, endIndex, callback) ->
	# 	assert.ok user? and repositoryId? and startIndex? and endIndex? and callback? and startIndex <= endIndex
	# 	builds = (@_createFakeBuild null, buildNumber for buildNumber in [startIndex...endIndex])
	# 	callback null, builds


	# _createFakeBuild: (id, number) ->
	# 	id: if id? then id else Math.floor Math.random() * 10000
	# 	number: if number? then number else Math.floor Math.random() * 10000
	# 	owner: 'Jordan Potter'
	# 	progress: Math.floor Math.random() * 100
	# 	success: false
