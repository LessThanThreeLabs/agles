assert = require 'assert'

Resource = require './resource'


exports.create = (modelRpcConnection) ->
	return new OrganizationsResource modelRpcConnection


class OrganizationsResource extends Resource
	create: (session, data, callback) ->
		
