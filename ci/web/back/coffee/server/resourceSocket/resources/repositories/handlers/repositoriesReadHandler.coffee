assert = require 'assert'

Handler = require '../../handler'


exports.create = (configurationParams, modelRpcConnection) ->
	return new RepositoriesReadHandler configurationParams, modelRpcConnection


class RepositoriesReadHandler extends Handler

	constructor: (@configurationParams, modelRpcConnection) ->
		assert.ok @configurationParams?
		super modelRpcConnection


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
				cloneUrl = @configurationParams.domain + ":" + url
				callback null, cloneUrl


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
		assert.ok args.repositoryId?
		userId = socket.session.userId

		if not userId?
			callback 403
			return

		@modelRpcConnection.repos.read.get_visible_repo_menuoptions userId, args.repositoryId, (error, menuOptions) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to get menu options'
			else
				callback null, menuOptions


	getMembersWithPermissions: (socket, args, callback) =>
		assert.ok socket.session.userId?
		assert.ok args.repositoryId?

		userId = socket.session.userId

		if not userId?
			callback 403
			return

		@modelRpcConnection.repos.read.get_members_with_permissions userId, args.repositoryId,
			(error, users) =>
				if error?
					if error.type is 'InvalidPermissionsError' then callback 403
					else callback 'unable to get repository members'
				else
					callback null, @_filterPermitted((@_sanitizeUser user for user in users))


	_sanitize: (repository) =>
		id: repository.id
		name: repository.name
		defaultPermissions: repository.defaultPermissions


	_sanitizeUser: (user) =>
		id: user.id
		firstName: user.first_name
		lastName: user.last_name
		email: user.email
		permissions: @_toPermissionString user.permissions


	_toPermissionString: (permissions) =>
		switch permissions
			when 1 then "r"
			when 3 then "r/w"
			when 7 then "r/w/a"
			else ""


	_filterPermitted: (users) =>
		(user for user in users when user.permissions.length)
