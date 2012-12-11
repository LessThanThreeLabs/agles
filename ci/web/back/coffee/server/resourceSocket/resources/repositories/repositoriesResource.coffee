assert = require 'assert'

Resource = require '../resource'

RepositoriesCreateHandler = require './handlers/repositoriesCreateHandler'
RepositoriesReadHandler = require './handlers/repositoriesReadHandler'
RepositoriesUpdateHandler = require './handlers/repositoriesUpdateHandler'

exports.create = (configurationParams, stores, modelConnection) ->
	createHandler = RepositoriesCreateHandler.create modelConnection.rpcConnection
	readHandler = RepositoriesReadHandler.create modelConnection.rpcConnection
	updateHandler = RepositoriesUpdateHandler.create modelConnection.rpcConnection
	return new RepositoriesResource configurationParams, stores, modelConnection, createHandler, readHandler, updateHandler


class RepositoriesResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @createHandler, @readHandler, @updateHandler) ->
		super configurationParams, stores, modelConnection


	create: (socket, data, callback) =>
		@_call @createHandler, socket, data, callback
		

	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	update: (socket, data, callback) =>
		@_call @updateHandler, socket, data, callback


	subscribe: (socket, data, callback) =>
		console.log 'need to make sure this user is allowed to receive updates for id ' + data.id
		eventName = @modelConnection.eventConnection.repositories.registerForEvents socket, data.id
		callback null, eventName: eventName if callback?


	unsubscribe: (socket, data, callback) =>
		@modelConnection.eventConnection.repositories.unregisterForEvents socket, data.id
		callback null, 'ok' if callback?
