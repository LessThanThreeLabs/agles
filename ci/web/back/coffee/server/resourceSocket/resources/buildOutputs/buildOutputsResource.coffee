assert = require 'assert'

Resource = require '../resource'

BuildOutputsReadHandler = require './handlers/buildOutputsReadHandler'


exports.create = (configurationParams, stores, modelConnection) ->
	readHandler = BuildOutputsReadHandler.create modelConnection.rpcConnection
	return new BuildOutputsResource configurationParams, stores, modelConnection, readHandler


class BuildOutputsResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @readHandler) ->
		super configurationParams, stores, modelConnection


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	subscribe: (socket, data, callback) =>
		console.log 'need to make sure this user is allowed to receive updates for id ' + data.id
		eventName = @modelConnection.eventConnection.buildOutputs.registerForEvents socket, data.id
		callback null, eventName: eventName if callback?


	unsubscribe: (socket, data, callback) =>
		@modelConnection.eventConnection.buildOutputs.unregisterForEvents socket, data.id
		callback null, 'ok' if callback?
