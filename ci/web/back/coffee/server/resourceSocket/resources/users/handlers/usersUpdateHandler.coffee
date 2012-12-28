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
		if not @accountInformationValidator.isValidFirstName data.firstName
			errors.firstName = @accountInformationValidator.getInvalidFirstNameString()
		if not @accountInformationValidator.isValidLastName data.lastName 
			errors.lastName = @accountInformationValidator.getInvalidLastNameString()
		# if not @accountInformationValidator.isValidEmail data.email
			# errors.email = @accountInformationValidator.getInvalidEmailString()

		if Object.keys(errors).length != 0
			callback errors
			return

		args = {}
		args.first_name = data.firstName if data.firstName?
		args.last_name = data.lastName if data.lastName?
		# args.email = data.email if data.email?
		args.password_hash = data.passwordHash if data.passwordHash?
		args.salt = data.salt if data.salt?

		@modelRpcConnection.users.update.update_user userId, args, (error, result) =>
			if error?
				errors.userUpdate = "Failed to update user"
				callback errors
			else
				socket.session.firstName = data.firstName
				socket.session.lastName = data.lastName
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
			callback 'parsing error'


	logout: (socket, data, callback) =>
		socket.session.destroy()
		callback null


	addSshKey: (socket, data, callback) =>
		errors = {}
		if not @accountInformationValidator.isValidSshAlias data.alias
			errors.alias = @accountInformationValidator.getInvalidSshAliasString()
		if not @accountInformationValidator.isValidSshKey data.sshKey
			errors.sshKey = @accountInformationValidator.getInvalidSshKeyString()

		if Object.keys(errors).length != 0
			callback errors
			return

		userId = socket.session.userId
		@modelRpcConnection.users.update.add_ssh_pubkey userId, data.alias, data.sshKey, (error, result) =>
			if error?
				errors.sshKeyAdd = 'failed to add key'
				callback errors
			else
				callback null, result


	removeSshKey: (socket, data, callback) =>
		assert.ok data.alias?

		userId = socket.session.userId
		@modelRpcConnection.users.update.remove_ssh_pubkey userId, data.alias, (error, result) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to remove ssh key'
			else
				callback null, result
