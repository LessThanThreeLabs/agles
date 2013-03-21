assert = require 'assert'
crypto = require 'crypto'

Handler = require '../../handler'


exports.create = (modelRpcConnection, passwordHasher, accountInformationValidator, mailer) ->
	return new UsersUpdateHandler modelRpcConnection, passwordHasher, accountInformationValidator, mailer


class UsersUpdateHandler extends Handler
	constructor: (modelRpcConnection, @passwordHasher, @accountInformationValidator, @mailer) ->
		super modelRpcConnection
		assert.ok @passwordHasher?
		assert.ok @accountInformationValidator?
		assert.ok @mailer?


	changeBasicInformation: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.firstName? or not data?.lastName?
			callback 400
		else
			errors = {}
			if not @accountInformationValidator.isValidFirstName data.firstName
				errors.firstName = @accountInformationValidator.getInvalidFirstNameString()
			if not @accountInformationValidator.isValidLastName data.lastName 
				errors.lastName = @accountInformationValidator.getInvalidLastNameString()

			if Object.keys(errors).length isnt 0
				callback errors
				return
				
			@modelRpcConnection.users.update.change_basic_information userId, data.firstName, data.lastName, (error, result) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()


	changePassword: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.oldPassword? or not data?.newPassword?
			callback 400
		else
			errors = {}
			if not @accountInformationValidator.isValidPassword data.newPassword
				errors.password = @accountInformationValidator.getInvalidPasswordString()

			if Object.keys(errors).length isnt 0
				callback errors
				return

			@modelRpcConnection.users.read.get_password_hash_and_salt userId, (error, result) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else
					oldPasswordHash = @passwordHasher.hashPasswordWithSalt data.oldPassword, result.salt
					if oldPasswordHash isnt result.password_hash
						callback 'Invalid old password'
						return
					
					newPasswordHash = @passwordHasher.hashPasswordWithSalt data.newPassword, result.salt
					@modelRpcConnection.users.update.change_password userId, newPasswordHash, result.salt, (error, result) =>
						if error?.type is 'InvalidPermissionsError' then callback 403
						else if error? then callback 500
						else callback()


	resetPassword: (socket, data, callback) =>
		if not data?.email?
			callback 400
		else
			@modelRpcConnection.users.read.get_user data.email, (error, user) =>
				if error? then callback 'user does not exist'
				else
					crypto.randomBytes 8, (error, randomBuffer) =>
						if error? then callback 500
						else
							newPassword = randomBuffer.toString 'base64'
							newPasswordHash = @passwordHasher.hashPasswordWithSalt newPassword, user.salt
							@modelRpcConnection.users.update.change_password user.id, newPasswordHash, user.salt, (error, result) =>
								if error? then callback 500
								else
									@mailer.resetPassword.email data.email, newPassword, (error) =>
										if error? then callback 500
										else callback()


	login: (socket, data, callback) =>
		if not data?.email? or not data?.password?
			callback 400
		else
			@modelRpcConnection.users.read.get_user data.email, (error, user) =>
				if error?.type is 'TimedOutError' then callback 500
				else if error? then callback 'bad login'
				else
					passwordHash = @passwordHasher.hashPasswordWithSalt data.password, user.salt

					if user.id < 1000 then callback 'bad login'
					else if passwordHash isnt user.password_hash then callback 'bad login'
					else
						socket.session.userId = user.id
						socket.session.save()

						callback()


	logout: (socket, data, callback) =>
		socket.session.destroy()
		callback()


	addSshKey: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.alias? or not data?.key?
			callback 400
		else
			errors = {}
			if not @accountInformationValidator.isValidSshAlias data.alias
				errors.alias = @accountInformationValidator.getInvalidSshAliasString()
			if not @accountInformationValidator.isValidSshKey data.key
				errors.sshKey = @accountInformationValidator.getInvalidSshKeyString()

			if Object.keys(errors).length isnt 0
				callback errors
				return

			@modelRpcConnection.users.update.add_ssh_pubkey userId, data.alias, data.key, (error, result) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, result


	removeSshKey: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.id?
			callback 400
		else
			@modelRpcConnection.users.update.remove_ssh_pubkey userId, data.id, (error, result) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback()


	submitFeedback: (socket, data, callback) =>
		sanitizeResult = (user) ->
			id: user.id
			email: user.email
			firstName: user.first_name
			lastName: user.last_name
			isAdmin: user.admin
			timestamp: user.created * 1000

		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.feedback? or not data?.userAgent? or not data?.screen?
			callback 400
		else
			@modelRpcConnection.users.read.get_user_from_id userId, (error, user) =>
				if error then callback 500
				else
					@mailer.feedback.email sanitizeResult(user), data.feedback, data.userAgent, data.screen
