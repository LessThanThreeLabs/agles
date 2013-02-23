assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesDeleteHandler modelRpcConnection


class RepositoriesDeleteHandler extends Handler
	deleteRepository: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.id?
			callback 400
		else
			@modelRpcConnection.repositories.delete.delete_repo userId, data.id, (error) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()