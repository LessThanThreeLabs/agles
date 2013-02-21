assert = require 'assert'

SshKeyPairGenerator = require './sshKeyPairGenerator'

Resource = require '../resource'
RepositoriesCreateHandler = require './handlers/repositoriesCreateHandler'
RepositoriesReadHandler = require './handlers/repositoriesReadHandler'


exports.create = (configurationParams, stores, modelConnection) ->
	sshKeyPairGenerator = SshKeyPairGenerator.create configurationParams

	createHandler = RepositoriesCreateHandler.create stores, modelConnection.rpcConnection, sshKeyPairGenerator
	readHandler = RepositoriesReadHandler.create configurationParams, modelConnection.rpcConnection
	return new RepositoriesResource configurationParams, stores, modelConnection, createHandler, readHandler


class RepositoriesResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @createHandler, @readHandler) ->
		super configurationParams, stores, modelConnection
		assert.ok @createHandler
		assert.ok @readHandler


	create: (socket, data, callback) =>
		@_call @createHandler, socket, data, callback
		

	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


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
