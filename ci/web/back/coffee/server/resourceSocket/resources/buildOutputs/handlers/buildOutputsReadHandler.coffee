assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildOutputsReadHandler modelRpcConnection


class BuildOutputsReadHandler extends Handler

	default: (socket, data, callback) =>
		@modelRpcConnection.buildOutputs.read.console_output socket.session.userId, data.id, (error, result) =>
			if error?
				callback error
			else
				callback null, result


	buildOutputIds: (socket, args, callback) =>
		@modelRpcConnection.buildOutputs.read.majortypes socket.session.userId, args.buildId, (error, result) =>
			if error?
				callback "hi"
			else
				delete result.chef
				callback null, result


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
		assert.ok socket.session.userId?
		assert.ok data.buildId? 
		userId = socket.session.userId

#		output = @modelRpcConnection.buildOutputs.read.get_console_output userId, 
#				data.buildId, data.consoleType, (error, lines) =>
#					if error?
#						callback "Could not read build output"
#					else
#						callback null, lines
