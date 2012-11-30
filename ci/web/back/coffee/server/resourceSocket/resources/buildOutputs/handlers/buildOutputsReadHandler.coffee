assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildOutputsReadHandler modelRpcConnection


class BuildOutputsReadHandler extends Handler

	default: (socket, data, callback) =>
		@modelRpcConnection.buildOutputs.read.get_console_output socket.session.userId, data.id, (error, result) =>
			if error?
				callback error
			else
				callback null, result


	getBuildConsoleIds: (socket, args, callback) =>
		@modelRpcConnection.buildOutputs.read.get_build_console_ids socket.session.userId, args.buildId, (error, result) =>
			if error?
				callback error
			else
				callback null, result
