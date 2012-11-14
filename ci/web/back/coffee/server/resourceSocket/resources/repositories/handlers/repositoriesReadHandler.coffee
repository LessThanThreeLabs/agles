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
		assert.ok socket.session.userId? and data.repoId?
		userId = socket.session.userId
		await @modelRpcConnection.repos.read.get_repo_from_id userId, 
				data.repoId, defer error, repo
		if error?
			callback "Could not read repo"
		else
			callback null, repo
 