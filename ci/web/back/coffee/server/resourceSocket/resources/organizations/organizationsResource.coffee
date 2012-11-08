assert = require 'assert'

Resource = require '../resource'

OrganizationsCreateHandler = require './handlers/organizationsCreateHandler'

exports.create = (configurationParams, stores, modelConnection) ->
	createHandler = OrganizationsCreateHandler.create modelConnection.rpcConnection
	return new OrganizationsResource configurationParams, stores, modelConnection, createHandler


class OrganizationsResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @createHandler) ->
		super configurationParams, stores, modelConnection


	create: (socket, data, callback) =>
		@_call @createHandler, socket, data, callback
