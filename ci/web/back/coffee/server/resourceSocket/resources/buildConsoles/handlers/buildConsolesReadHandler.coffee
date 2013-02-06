assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildConsolesReadHandler modelRpcConnection


class BuildConsolesReadHandler extends Handler
	getBuildConsoles: (socket, data, callback) =>
		returnCodeToStatus = (returnCode) ->
			if not returnCode? then return 'running'
			else if returnCode is 0 then return 'passed'
			else return 'failed'

		sanitizeResult = (buildConsole) ->
			id: buildConsole.id
			type: buildConsole.type
			name: buildConsole.subtype
			status: returnCodeToStatus buildConsole.return_code
 		
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.changeId?
			callback 400
		else
			@modelRpcConnection.buildConsoles.read.get_build_consoles userId, data.changeId, (error, buildConsoles) ->
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error?
					console.log error.traceback
					callback 500
				else callback null, (sanitizeResult buildConsole for buildConsole in buildConsoles)
