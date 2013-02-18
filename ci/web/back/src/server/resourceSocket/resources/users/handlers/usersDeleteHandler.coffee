assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new UsersDeleteHandler modelRpcConnection


class UsersDeleteHandler extends Handler
	deleteUser: (socket, data, callback) =>
		if not data?.id?
			callback 400
		else
			console.log 'need to delete user...'
			callback()