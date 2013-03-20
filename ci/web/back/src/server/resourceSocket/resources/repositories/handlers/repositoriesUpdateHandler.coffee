assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesReadHandler modelRpcConnection


class RepositoriesReadHandler extends Handler
	setForwardUrl: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.id? or not data?.forwardUrl?
			callback 400
		else
			@modelRpcConnection.repositories.update.set_forward_url userId, data.id, data.forwardUrl, (error, result) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()
