assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new ChangesReadHandler modelRpcConnection


class ChangesReadHandler extends Handler
	getMetadata: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data.changeId?
			callback 400
		else
			callback 'IMPLEMENT THIS!!'

			# @modelRpcConnection.changes.read.get_change_metadata userId, data.id, (error, metadata) =>
			# 	if error?
			# 		if error.type is 'InvalidPermissionsError' then callback 403
			# 		else callback 'unable to get metadata'
			# 	else
			# 		callback null, @_sanitizeMetadata metadata
