ssert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesReadHandler modelRpcConnection


class RepositoriesReadHandler extends Handler
	default: (socket, data, callback) =>
		assert.ok socket.session.userId? and data.repoId?
		userId = socket.session.userId
		repo = @modelRpcConnection.repos.read.get_repo_from_id(userId, data.repoId)
		callback null, repo
		