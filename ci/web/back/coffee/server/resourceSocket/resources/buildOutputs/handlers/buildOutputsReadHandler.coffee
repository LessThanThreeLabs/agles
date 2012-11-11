assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildOutputsReadHandler modelRpcConnection


class BuildOutputsReadHandler extends Handler
	default: (socket, data, callback) =>
		assert.ok socket.session.userId and data.buildId? and data.console?
		userId = socket.session.userId
		output = @modelRpcConnection.buildOutputs.read.get_console_output userId, data.buildId, data.console
		callback null, output
