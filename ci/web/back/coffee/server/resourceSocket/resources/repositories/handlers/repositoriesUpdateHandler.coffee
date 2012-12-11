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

		if not userId?
			callback 403
			return

		permissions = @_fromPermissionString args.permissions
		@modelRpcConnection.repos.update.change_member_permissions userId, args.email, args.repositoryId, permissions,
			(error, result) =>
				if error?
					if error.type is 'InvalidPermissionsError' then callback 403
					else callback 'unable to change permissions'
				else
					callback null, result


	removeMember: (socket, args, callback) =>
		assert.ok socket.session.userId?
		assert.ok args.repositoryId?
		assert.ok args.email?

		userId = socket.session.userId

		if not userId?
			callback 403
			return

		@modelRpcConnection.repos.update.remove_member userId, args.email, args.repositoryId,
			(error, result) =>
				if error?
					if error.type is 'InvalidPermissionsError' then callback 403
					else callback 'unable to remove members'
				else
					callback null, result


	_fromPermissionString: (permissions) =>
		switch permissions
			when "r" then 1
			when "r/w" then 3
			when "r/w/a" then 7
			else 0
