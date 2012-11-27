assert = require 'assert'

Resource = require '../resource'

BuildsReadHandler = require './handlers/buildsReadHandler'

exports.create = (configurationParams, stores, modelConnection) ->
	readHandler = BuildsReadHandler.create modelConnection.rpcConnection
	return new BuildsResource configurationParams, stores, modelConnection, readHandler


class BuildsResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @readHandler) ->
		super configurationParams, stores, modelConnection


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback
