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
		@_call @subscribeHandler, socket, data, callback
		