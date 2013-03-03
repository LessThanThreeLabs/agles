assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildConsolesReadHandler modelRpcConnection


class BuildConsolesReadHandler extends Handler
	getBuildConsole: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.id? or not data?.repositoryId?
			callback 400
		else
			@modelRpcConnection.buildConsoles.read.get_build_console_from_id userId, data.id, (error, buildConsole) =>
				if error?.type is 'InvalidPermissionsError' or buildConsole.repo_id isnt data.repositoryId then callback 403
				else if error? then callback 500
				else callback null, @_sanitizeBuildConsole buildConsole


	getBuildConsoles: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.changeId?
			callback 400
		else
			@modelRpcConnection.buildConsoles.read.get_build_consoles userId, data.changeId, (error, buildConsoles) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, (@_sanitizeBuildConsole buildConsole for buildConsole in buildConsoles)


	getLines: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.id?
			callback 400
		else
			@modelRpcConnection.buildConsoles.read.get_output_lines userId, data.id, (error, buildConsolesLines) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, buildConsolesLines


	_sanitizeBuildConsole: (buildConsole) =>
		returnCodeToStatus = (returnCode) ->
			if not returnCode? then return 'running'
			else if returnCode is 0 then return 'passed'
			else return 'failed'

		id: buildConsole.id
		type: buildConsole.type
		name: buildConsole.subtype
		status: returnCodeToStatus buildConsole.return_code
