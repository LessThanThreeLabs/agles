assert = require 'assert'

RepositoriesHandler = require './repositoriesHandler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesCreateHandler modelRpcConnection


class RepositoriesCreateHandler extends RepositoriesHandler

	default: (socket, data, callback) =>
		assert.ok data.name?
		assert.ok data.description?
		assert.ok data.forwardUrl?

		userId = socket.session.userId

		if not userId?
			callback 403
			return

		@modelRpcConnection.repos.create.create_repo userId, data.name, data.description,
			@_fromPermissionString('r/w'), data.forwardUrl, (error, repositoryId) =>
				if error?
					callback "Failed to create repository. Please check that the name, description, and url are valid."
				else
					callback null, repositoryId
