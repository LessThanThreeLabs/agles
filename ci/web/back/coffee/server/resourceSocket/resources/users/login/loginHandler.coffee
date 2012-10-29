assert = require 'assert'


exports.create = (configurationParams, modelRpcConnection, passwordHasher) ->
	return new LoginHandler configurationParams, modelRpcConnection, passwordHasher


class LoginHandler
	constructor: (@configurationParams, @modelRpcConnection, @passwordHasher) ->
		assert.ok @configurationParams? and @modelRpcConnection? and @passwordHasher?


	handleRequest: (socket, data, callback) =>
		console.log 'need to handle login'

		# modelRpcConnection.users.read.getPasswordSalt email, (error, result) =>
		# 	hashedPassword = @passwordHasher.hashPasswordWithSalt password, result.salt
		# 	modelRpcConnection.users.read.get email, hashedPassword, (error, result) =>
		# 		console.log 'got user: ' + result.user

		callback null, 
			firstName: 'Jordan'
			lastName: 'Potter'
			