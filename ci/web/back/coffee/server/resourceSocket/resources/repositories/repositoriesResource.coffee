assert = require 'assert'

Resource = require '../resource'

RepositoriesReadHandler = require './handlers/repositoriesReadHandler'
RepositoriesSubscribeHandler = require './handlers/repositoriesSubscribeHandler'

exports.create = (configurationParams, stores, modelConnection) ->
	readHandler = RepositoriesReadHandler.create modelConnection.rpcConnection
	subscribeHandler = RepositoriesSubscribeHandler.create modelConnection.rpcConnection
	return new RepositoriesResource configurationParams, stores, modelConnection, readHandler, subscribeHandler


class RepositoriesResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @readHandler, @subscribeHandler) ->
		super configurationParams, stores, modelConnection


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	subscribe: (socket, data, callback) =>
		console.log 'need to make sure this user is allowed to receive updates for id ' + data.id
		eventName = @modelConnection.eventConnection.repositories.registerForEvents socket, data.id
		callback null, eventName: eventName if callback?


	unsubscribe: (socket, data, callback) =>
		@modelConnection.eventConnection.repositories.unregisterForEvents socket, data.id
		callback null, 'ok' if callback?
