assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new UsersReadHandler modelRpcConnection


class UsersReadHandler extends Handler
	getSshKeys: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.users.read.get_ssh_keys userId, (error, keys) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, keys
