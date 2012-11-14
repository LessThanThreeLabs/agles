assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildOutputsReadHandler modelRpcConnection


class BuildOutputsReadHandler extends Handler

	# not sure this is needed...
	default: (socket, data, callback) =>
		assert.ok socket.session.userId and data.buildId? and data.console?
		userId = socket.session.userId
		output = @modelRpcConnection.buildOutputs.read.get_console_output userId, data.buildId, data.console
		callback null, output


	# -- GIVEN --
	# data =
	#   buildId: <string>
	# -- RETURNED --
	# result =
	#   lines: [
	#     number: <integer>
	#     text: <string>
	#   ]
	getOutputForBuild: (socket, data, callback) =>
		callback 'Not yet implemented...'
