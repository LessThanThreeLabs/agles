assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new BuildsReadHandler modelRpcConnection


class BuildsReadHandler extends Handler

	default: (socket, data, callback) =>
		assert.ok socket.session.userId? and data.id?
		userId = socket.session.userId
		@modelRpcConnection.builds.read.get_visible_build_from_id userId, data.id, (error, buildData) =>
			if error?
				callback "Cannot locate build"
			else
				callback null, buildData
