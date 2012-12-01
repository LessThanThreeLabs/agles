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