assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesReadHandler modelRpcConnection


class RepositoriesReadHandler extends Handler

	# -- GIVEN --
	# data =
	#   id: <integer>
	# -- RETURNED --
	# result =
	#   EVERYTHING for now...
	default: (socket, data, callback) =>
		assert.ok socket.session.userId? and data.id?
		userId = socket.session.userId
		@modelRpcConnection.repos.read.get_repo_from_id userId, data.id, (error, repo) =>
			if error?
				callback "Could not read repo"
			else
				callback null, repo
 