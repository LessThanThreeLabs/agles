assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new UsersDeleteHandler modelRpcConnection


class UsersDeleteHandler extends Handler
	deleteUser: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.id?
			callback 400
		else
			@modelRpcConnection.users.delete.delete_user userId, data.id, (error, userId) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()
