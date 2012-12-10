assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesUpdateHandler modelRpcConnection


class RepositoriesUpdateHandler extends Handler
	changeMemberPermissions: (socket, args, callback) =>
		assert.ok socket.session.userId?
		assert.ok args.repositoryId?
		assert.ok args.email?
		assert.ok args.permissions?

		userId = socket.session.userId
		permissions = @_fromPermissionString args.permissions
		@modelRpcConnection.repos.update.change_member_permissions userId, args.email, args.repositoryId, permissions,
			(error, result) =>
				if error?
					callback error
				else
					callback null, result


	removeMember: (socket, args, callback) =>
		assert.ok socket.session.userId?
		assert.ok args.repositoryId?
		assert.ok args.email?

		userId = socket.session.userId
		@modelRpcConnection.repos.update.remove_member userId, args.email, args.repositoryId,
			(error, result) =>
				if error?
					callback error
				else
					callback null, result


	_fromPermissionString: (permissions) =>
		switch permissions
			when "r" then 1
			when "r/w" then 3
			when "r/w/a" then 7
			else 0
