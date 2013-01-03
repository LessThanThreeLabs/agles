assert = require 'assert'

Resource = require '../resource'

ChangesReadHandler = require './handlers/changesReadHandler'

exports.create = (configurationParams, stores, modelConnection) ->
	readHandler = ChangesReadHandler.create modelConnection.rpcConnection
	return new ChangesResource configurationParams, stores, modelConnection, readHandler


class ChangesResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @readHandler) ->
		super configurationParams, stores, modelConnection


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	subscribe: (socket, data, callback) =>
		console.log 'need to make sure this user is allowed to receive updates for id ' + data.id
		eventName = @modelConnection.eventConnection.changes.registerForEvents socket, data.id
		callback null, eventName: eventName if callback?


	unsubscribe: (socket, data, callback) =>
		@modelConnection.eventConnection.changes.unregisterForEvents socket, data.id
		callback null, 'ok' if callback?
