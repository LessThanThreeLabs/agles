assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildConsolesReadHandler modelRpcConnection


class BuildConsolesReadHandler extends Handler
	getBuildOutputs: (socket, data, callback) =>
		# sanitizeResult = (change) ->
		# 	id: change.id
		# 	number: change.number
		# 	status: change.status
 		
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.changeId?
			callback 400
		else
			@modelRpcConnection.buildConsoles.read.get_build_consoles userId, data.changeId, (error, buildConsoles) =>
					if error?.type is 'InvalidPermissionsError' then callback 403
					else if error? then callback 500
					else callback null, buildOutputs
