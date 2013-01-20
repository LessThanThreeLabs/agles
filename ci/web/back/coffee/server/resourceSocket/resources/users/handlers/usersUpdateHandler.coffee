assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, loginHandler, passwordHasher, accountInformationValidator, resetPasswordEmailer) ->
	return new UsersUpdateHandler modelRpcConnection, loginHandler, passwordHasher, accountInformationValidator, resetPasswordEmailer


class UsersUpdateHandler extends Handler
	constructor: (modelRpcConnection, @loginHandler, @passwordHasher, @accountInformationValidator, @resetPasswordEmailer) ->
		assert.ok modelRpcConnection?
		assert.ok @loginHandler?
		assert.ok @passwordHasher?
		assert.ok @accountInformationValidator?
		assert.ok @resetPasswordEmailer

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


	updatePassword: (socket, data, callback) =>
		assert.ok data.oldPassword?
		assert.ok data.newPassword?
		assert.ok data.confirmPassword?
		userId = socket.session.userId

		errors = {}

		if data.newPassword != data.confirmPassword
			errors.confirmPassword = 'New password and confirmed password do not match'
			callback errors
			return
		else if not @accountInformationValidator.isValidPassword data.newPassword
			errors.newPassword = @accountInformationValidator.getInvalidPasswordString()
			callback errors
			return

		@modelRpcConnection.users.read.get_user_from_id userId, (error, userData) =>
			if error?
				callback 'Unexpected error'
			else
				oldPasswordHash = @passwordHasher.hashPasswordWithSalt data.oldPassword, userData.salt
				if userData.password_hash != oldPasswordHash
					errors.oldPassword = 'Old password is not correct'
					callback errors
					return

				newPasswordHash = @passwordHasher.hashPasswordWithSalt data.newPassword, userData.salt
				@modelRpcConnection.users.update.update_user userId, {password_hash: newPasswordHash}, (error, result) =>
					if error?
						callback 'Unexpected error'
					else
						callback null, result


	resetPassword: (socket, data, callback) =>
		assert.ok data.email?

		newPassword = Number(Math.random().toString().substr(2)).toString 36

		@modelRpcConnection.users.update.reset_password data.email, newPassword, (error) =>
			if error?
				callback 'Unable to send email'
			else
				@resetPasswordEmailer.sendEmailToUser data.email, newPassword, (error) ->
				if error?
					console.error error 
					callback 'Unable to send email'
				else
					callback()


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
