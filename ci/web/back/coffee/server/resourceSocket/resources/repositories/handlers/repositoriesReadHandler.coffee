assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesReadHandler modelRpcConnection


class RepositoriesReadHandler extends Handler
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


	writableRepositories: (socket, args, callback) =>
		userId = socket.session.userId
		if not userId?
			callback null, []
		else
			@modelRpcConnection.repos.read.get_writable_repos userId, (error, repositories) =>
				if error?
					callback error
				else
					callback null, (@_sanitize repo for repo in repositories)


	getMenuOptions: (socket, args, callback) =>
		assert.ok socket.session.userId?
		assert.ok args.repositoryId?

		userId = socket.session.userId
		@modelRpcConnection.repos.read.get_visible_repo_menuoptions userId, args.repositoryId, 
			(error, menuOptions) =>
				if error?
					callback error
				else
					callback null, menuOptions


	_sanitize: (repository) =>
		id: repository.id
		name: repository.name
		defaultPermissions: repository.defaultPermissions
