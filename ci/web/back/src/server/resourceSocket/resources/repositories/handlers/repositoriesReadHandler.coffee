assert = require 'assert'

Handler = require '../../handler'


exports.create = (configurationParams, modelRpcConnection) ->
	return new RepositoriesReadHandler configurationParams, modelRpcConnection


class RepositoriesReadHandler extends Handler
	constructor: (@configurationParams, modelRpcConnection) ->
		assert.ok @configurationParams?
		super modelRpcConnection


	getRepositories: (socket, data, callback) =>
		sanitizeResult = (repository) ->
			id: repository.id
			name: repository.name
			timestamp: 0

		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.repositories.read.get_repositories userId, (error, repositories) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, (sanitizeResult repository for repository in repositories)
