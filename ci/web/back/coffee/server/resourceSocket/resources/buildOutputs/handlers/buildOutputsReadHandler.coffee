assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildOutputsReadHandler modelRpcConnection


class BuildOutputsReadHandler extends Handler
