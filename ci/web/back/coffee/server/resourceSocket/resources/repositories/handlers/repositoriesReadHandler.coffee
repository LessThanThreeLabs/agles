assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesReadHandler modelRpcConnection


class RepositoriesReadHandler extends Handler

	default: (socket, data, callback) =>
		assert.ok data.id?
		userId = socket.session.userId
		
		if not userId?
			callback 403
			return

		@modelRpcConnection.repos.read.get_repo_from_id userId, data.id, (error, repo) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to read repositories'
			else
				callback null, repo


	getCloneUrl: (socket, args, callback) =>
		assert.ok args.repositoryId?
		userId = socket.session.userId

		if not userId?
			callback 403
			return

		@modelRpcConnection.repos.read.get_clone_url userId, args.repositoryId, (error, url) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to get clone url'
			else
				callback null, url


	writableRepositories: (socket, args, callback) =>
		userId = socket.session.userId

		if not userId?
			callback 403
			return

		@modelRpcConnection.repos.read.get_writable_repos userId, (error, repositories) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to get writable repositories'
			else
				callback null, (@_sanitize repo for repo in repositories)


	getMenuOptions: (socket, args, callback) =>
		assert.ok socket.session.userId?
		assert.ok args.repositoryId?
		userId = socket.session.userId

		@modelRpcConnection.repos.read.get_visible_repo_menuoptions userId, args.repositoryId, (error, menuOptions) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to get menu options'
			else
				callback null, menuOptions


	_sanitize: (repository) =>
		id: repository.id
		name: repository.name
		defaultPermissions: repository.defaultPermissions
