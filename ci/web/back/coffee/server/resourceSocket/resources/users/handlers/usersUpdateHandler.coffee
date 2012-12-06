assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, loginHandler) ->
	return new UsersUpdateHandler modelRpcConnection, loginHandler


class UsersUpdateHandler extends Handler
	constructor: (modelRpcConnection, @loginHandler) ->
		assert.ok modelRpcConnection? and @loginHandler?
		super modelRpcConnection


	default: (socket, data, callback) =>
		userId = socket.session.userId

		errors = {}
		if not data.first_name? or data.first_name is ''
			errors.firstName = "Invalid First Name"
		if not data.last_name? or data.last_name is ''
			errors.lastName = "Invalid Last Name"
		if not data.email? or data.email is ''
			errors.email = "Invalid Email"

		if Object.keys(errors).length != 0
			callback errors
			return

		@modelRpcConnection.users.update.update_user userId, data, (error, result) =>
			if error?
				callback "User failed to update"
			else
				callback null, result


	# -- GIVEN --
	# data =
	#   email: <string>
	#   password: <string>
	# -- RETURNED --
	# errors = UNDEFINED RIGHT NOW
	# result =
	#   firstName: <string>
	#   lastName: <string>
	login: (socket, data, callback) =>
		if data.email? and data.password? and data.rememberMe?
			@loginHandler.handleRequest socket, data, callback
		else
			callback 'Malformed request.'


	addSshKey: (socket, data, callback) =>
		errors = {}
		if not data.alias? or data.alias is ''
			errors.alias = "Invalid Alias"
		if not data.sshKey? or data.sshKey is ''
			errors.sshKey = "Invalid Key"

		if Object.keys(errors).length != 0
			callback errors
			return

		userId = socket.session.userId
		@modelRpcConnection.users.update.add_ssh_pubkey userId, data.alias, data.sshKey, (error, result) =>
			if error?
				callback "Failed to add Key"
			else
				callback null, result


	removeSshKey: (socket, data, callback) =>
		assert.ok data.alias?

		userId = socket.session.userId
		@modelRpcConnection.users.update.delete_ssh_pubkey userId, data.alias, (error, result) =>
			if error?
				callback "Failed to remove SSH key"
			else
				callback null, result