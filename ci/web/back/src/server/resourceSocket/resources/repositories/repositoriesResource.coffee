assert = require 'assert'

SshKeyGenerator = require './sshKeyGenerator'

Resource = require '../resource'
RepositoriesCreateHandler = require './handlers/repositoriesCreateHandler'
RepositoriesReadHandler = require './handlers/repositoriesReadHandler'
RepositoriesUpdateHandler = require './handlers/repositoriesUpdateHandler'


exports.create = (configurationParams, stores, modelConnection) ->
	sshKeyGenerator = SshKeyGenerator.create()

	createHandler = RepositoriesCreateHandler.create modelConnection.rpcConnection, sshKeyGenerator
	readHandler = RepositoriesReadHandler.create configurationParams, modelConnection.rpcConnection
	updateHandler = RepositoriesUpdateHandler.create modelConnection.rpcConnection
	return new RepositoriesResource configurationParams, stores, modelConnection, createHandler, readHandler, updateHandler


class RepositoriesResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @createHandler, @readHandler, @updateHandler) ->
		super configurationParams, stores, modelConnection
		assert.ok @createHandler
		assert.ok @readHandler
		assert.ok @updateHandler


	create: (socket, data, callback) =>
		@_call @createHandler, socket, data, callback
		

	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	update: (socket, data, callback) =>
		@_call @updateHandler, socket, data, callback


	subscribe: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		if typeof data.method isnt 'string' or typeof data.args?.id isnt 'number'
			callback 400
		else
			console.log 'need to make sure this user is allowed to receive updates for id ' + data.args.id
			eventName = @modelConnection.eventConnection.repositories.registerForEvents socket, data.args.id, data.method
			if eventName? then callback null, eventName
			else callback 400


	unsubscribe: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		if typeof data.method isnt 'string' or typeof data.args?.id isnt 'number'
			callback 400
		else
			success = @modelConnection.eventConnection.repositories.unregisterForEvents socket, data.args.id, data.method
			if success then callback()
			else callback 400
