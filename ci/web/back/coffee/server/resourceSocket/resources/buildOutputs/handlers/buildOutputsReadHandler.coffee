assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildOutputsReadHandler modelRpcConnection


class BuildOutputsReadHandler extends Handler

	default: (socket, data, callback) =>
		callback 'Not yet implemented...'


	# -- GIVEN --
	# data =
	#   buildId: <string>
	#	consoleType: <string>
	# -- RETURNED --
	# result =
	#   lines: [
	#     number: <integer>
	#     text: <string>
	#   ]
	getOutputForBuild: (socket, data, callback) =>
		assert.ok socket.session.userId and data.buildId? and data.consoleType?
		userId = socket.session.userId
		output = @modelRpcConnection.buildOutputs.read.get_console_output userId, 
				data.buildId, data.consoleType, (error, lines) =>
					if error?
						callback "Could not read build output"
					else
						callback null, lines
