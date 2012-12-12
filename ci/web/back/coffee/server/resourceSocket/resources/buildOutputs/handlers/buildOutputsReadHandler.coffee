assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildOutputsReadHandler modelRpcConnection


class BuildOutputsReadHandler extends Handler

	default: (socket, data, callback) =>
		@modelRpcConnection.buildOutputs.read.get_console_output socket.session.userId, data.id, (error, result) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to read build output'
			else
				callback null, @_sanitizeDefault result


	_sanitizeDefault: (result) =>
		title: result.subtype
		consoleOutput: result.console_output


	getBuildConsoleIds: (socket, args, callback) =>
		@modelRpcConnection.changes.read.get_visible_builds_from_change_id socket.session.userId, args.changeId, (error, builds) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to read build console ids'
				return

			errors = []
			results = []

			await
				for build, index in builds
					@modelRpcConnection.buildOutputs.read.get_build_console_ids socket.session.userId, build.id, defer errors[index], results[index]

			for error in errors
				if error?
					if error.type is 'InvalidPermissionsError' then callback 403
					else callback 'unable to read build console ids'
					return

			callback null, results
