assert = require 'assert'

Resource = require '../resource'


exports.create = (configurationParams, modelRpcConnection) ->
	return new OrganizationsResource configurationParams, modelRpcConnection


class OrganizationsResource extends Resource
	create: (session, data, callback) ->
		
