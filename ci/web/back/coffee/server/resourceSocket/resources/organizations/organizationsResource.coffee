assert = require 'assert'

Resource = require '../resource'


exports.create = (configurationParams, stores, modelRpcConnection) ->
	return new OrganizationsResource configurationParams, stores, modelRpcConnection


class OrganizationsResource extends Resource
	create: (session, data, callback) ->
