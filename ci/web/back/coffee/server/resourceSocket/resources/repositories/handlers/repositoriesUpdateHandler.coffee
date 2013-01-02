assert = require 'assert'

RepositoriesHandler = require './repositoriesHandler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesUpdateHandler modelRpcConnection


class RepositoriesUpdateHandler extends RepositoriesHandler
	updateDescription: (socket, args, callback) =>
		assert.ok args.repositoryId?
		assert.ok args.description?

		userId = socket.session.userId

		if not userId?
			callback 403
			return

		errors = {}

		@modelRpcConnection.repos.update.update_description userId, args.repositoryId, args.description, (error, result) =>
			if error?
				errors.description = "Update of repository description failed"
				callback errors
			else
				callback null, result


	inviteMembers: (socket, args, callback) =>
		assert.ok socket.session.userId?
		assert.ok args.repositoryId?
		assert.ok args.emails?

		userId = socket.session.userId

		if not userId?
			callback 403
			return

		errors = []
		results = []

		await
			for email, index in args.emails
				console.log email
				@modelRpcConnection.repos.update.add_member userId, email, args.repositoryId, defer errors[index], results[index]

		for error, index in errors
			if error?
				if error.type is 'InvalidPermissionsError'
					callback 403
					return
				else errors[index] = args.emails[index]

		errors = errors.filter (error) => error?
		errors = if errors.length > 0 then errors else null

		callback errors, results


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
