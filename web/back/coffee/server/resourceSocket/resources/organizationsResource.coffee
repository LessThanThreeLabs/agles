assert = require 'assert'

Resource = require './resource'


exports.create = (modelConnection) ->
	return new OrganizationsResource modelConnection


class OrganizationsResource extends Resource
	create: (session, data, callback) ->
		callback 'create not written yet' if callback?


	read: (session, data, callback) ->
		callback 'read not written yet' if callback?


	update: (session, data, callback) ->
		callback 'update not written yet' if callback?


	delete: (session, data, callback) ->
		callback 'delete not written yet' if callback?
