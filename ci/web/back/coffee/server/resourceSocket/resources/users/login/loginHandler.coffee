assert = require 'assert'


exports.create = (configurationParams, modelRpcConnection, passwordHasher) ->
	return new LoginHandler configurationParams, modelRpcConnection, passwordHasher


class LoginHandler
	constructor: (@configurationParams, @modelRpcConnection, @passwordHasher) ->
		assert.ok @configurationParams? and @modelRpcConnection? and @passwordHasher?


	handleRequest: (socket, data, callback) =>
		# socket.session.userId = user_id
		# socket.session.save()

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
				socket.session.save()
				callback error, @_sanitize user

	_sanitize: (user) =>
		firstName: user.first_name
		lastName: user.last_name
		email: user.email
		id: user.id

		# modelRpcConnection.users.read.getPasswordSalt email, (error, result) =>
		# 	hashedPassword = @passwordHasher.hashPasswordWithSalt password, result.salt
		# 	modelRpcConnection.users.read.get email, hashedPassword, (error, result) =>
		# 		console.log 'got user: ' + result.user

		#callback null, 
		#	firstName: 'Jordan'
		#	lastName: 'Potter'
			