assert = require 'assert'

Resource = require './resource'


exports.create = (modelConnection) ->
	return new OrganizationsResource modelConnection


class OrganizationsResource extends Resource
	create: (session, data, callback) ->
		
