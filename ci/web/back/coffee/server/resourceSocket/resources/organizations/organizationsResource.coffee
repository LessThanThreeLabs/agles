assert = require 'assert'

Resource = require '../resource'


exports.create = (configurationParams, stores, modelConnection) ->
	return new OrganizationsResource configurationParams, stores, modelConnection


class OrganizationsResource extends Resource
	create: (session, data, callback) ->
