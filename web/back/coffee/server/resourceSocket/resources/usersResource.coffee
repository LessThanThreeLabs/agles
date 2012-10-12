assert = require 'assert'

Resource = require './resource'


exports.create = (modelRpcConnection) ->
	return new UsersResource modelRpcConnection


class UsersResource extends Resource
	update: (socket, data, callback) ->
		if data.email? and data.password?
			console.log 'need to check that the username and password are correct from the model server'
			callback null, true
		else
			callback 'Parsing error'
