assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, loginHandler, accountInformationValidator) ->
	return new UsersUpdateHandler modelRpcConnection, loginHandler, accountInformationValidator


class UsersUpdateHandler extends Handler
	constructor: (modelRpcConnection, @loginHandler, @accountInformationValidator) ->
		assert.ok modelRpcConnection? 
		assert.ok @loginHandler?
		assert.ok @accountInformationValidator?

		super modelRpcConnection


	default: (socket, data, callback) =>
		userId = socket.session.userId

		errors = {}
		if not @accountInformationValidator.validFirstName data.first_name
			errors.firstName = "Invalid First Name"
		if not @accountInformationValidator.validLastName data.last_name 
			errors.lastName = "Invalid Last Name"
		if not @accountInformationValidator.validEmail data.email
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
		if not @accountInformationValidator.validSshAlias data.alias
			errors.alias = "Invalid Alias"
		if not @accountInformationValidator.validSshKey data.sshKey
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