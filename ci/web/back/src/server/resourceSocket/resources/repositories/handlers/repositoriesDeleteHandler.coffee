assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, passwordHasher) ->
	return new RepositoriesDeleteHandler modelRpcConnection, passwordHasher


class RepositoriesDeleteHandler extends Handler
	constructor: (modelRpcConnection, @passwordHasher) ->
		super modelRpcConnection
		assert.ok @passwordHasher?


	deleteRepository: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.id? or not data?.password
			callback 400
		else
			@modelRpcConnection.users.read.get_user_from_id userId, (error, user) =>
				if error? then callback 403
				else
					passwordHash = @passwordHasher.hashPasswordWithSalt data.password, user.salt

					if passwordHash isnt user.password_hash then callback 403
					else
						@modelRpcConnection.repositories.delete.delete_repo userId, data.id, (error) =>
							if error?.type is 'InvalidPermissionsError' then callback 403
							else if error? then callback 500
							else callback()
