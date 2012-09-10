assert = require 'assert'

Resource = require './resource'


exports.create = (modelConnection) ->
	return new RepositoriesResource modelConnection


class RepositoriesResource extends Resource
	read: (session, data, callback) ->
		callback 'read not written yet' if callback?
