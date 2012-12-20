assert = require 'assert'


exports.create = (configurationParams, modelRpcConnection, passwordHasher) ->
	return new LoginHandler configurationParams, modelRpcConnection, passwordHasher


class LoginHandler
	constructor: (@configurationParams, @modelRpcConnection, @passwordHasher) ->
		assert.ok @configurationParams? and @modelRpcConnection? and @passwordHasher?


	handleRequest: (socket, data, callback) =>
		@modelRpcConnection.users.read.get_salt data.email, (error, salt) =>
			if error?
				callback 'Login failed'
				return

			hashedPassword = @passwordHasher.hashPasswordWithSalt data.password, salt
			@modelRpcConnection.users.read.get_user data.email, hashedPassword, (error, user) =>
				if error?
					callback 'Login failed'
					return

				socket.session.userId = user.id
				socket.session.email = user.email
				socket.session.firstName = user.first_name
				socket.session.lastName = user.last_name
				socket.session.save()

				callback null, @_sanitize user


	_sanitize: (user) =>
		id: user.id
		email: user.email
		firstName: user.first_name
		lastName: user.last_name
