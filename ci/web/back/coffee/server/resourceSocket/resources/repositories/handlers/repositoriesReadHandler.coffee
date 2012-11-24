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
		assert.ok data.id?
		userId = socket.session.userId
		
		if not userId?
			callback "404"
			return

		@modelRpcConnection.repos.read.get_repo_from_id userId, data.id, (error, repo) =>
			if error?
				callback "Could not read repo"
			else
				callback null, repo
 