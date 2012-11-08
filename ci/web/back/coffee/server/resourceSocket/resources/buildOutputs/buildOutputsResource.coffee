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
