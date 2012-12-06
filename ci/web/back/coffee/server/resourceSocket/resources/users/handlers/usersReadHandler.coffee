assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new UsersReadHandler modelRpcConnection


class UsersReadHandler extends Handler
	constructor: (modelRpcConnection) ->
		assert.ok modelRpcConnection?
		super modelRpcConnection


	default: (socket, data, callback) =>
		userId = socket.session.userId
		@modelRpcConnection.users.read.get_user_from_id userId, (error, user) =>
			if error?
				callback error
			else
				callback @_sanitize user


	_sanitize: (user) =>
		id: user.id
		firstName: user.first_name
		lastName: user.last_name
		email: user.email