assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, passwordHasher, accountInformationValidator, resetPasswordEmailer) ->
	return new UsersUpdateHandler modelRpcConnection, passwordHasher, accountInformationValidator, resetPasswordEmailer


class UsersUpdateHandler extends Handler
	constructor: (modelRpcConnection, @passwordHasher, @accountInformationValidator, @resetPasswordEmailer) ->
		super modelRpcConnection
		assert.ok @passwordHasher?
		assert.ok @accountInformationValidator?
		assert.ok @resetPasswordEmailer


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
				else
					socket.session.firstName = data.firstName
					socket.session.lastName = data.lastName
					socket.session.save()
					
					callback()


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


	_createRandomPassword: () ->
		return Number(Math.random().toString().substr(2)).toString(36) + Number(Math.random().toString().substr(2)).toString(36)


	resetPassword: (socket, data, callback) =>
		if not data?.email?
			callback 400
		else
			@modelRpcConnection.users.read.get_user data.email, (error, user) =>
				if error? then callback 500
				else
					newPassword = @_createRandomPassword()
					newPasswordHash = @passwordHasher.hashPasswordWithSalt newPassword, user.salt
					@modelRpcConnection.users.update.change_password userId, newPasswordHash, (error, result) =>
						if error? then callback 500
						else
							@resetPasswordEmailer.sendEmailToUser data.email, newPassword, (error) =>
								if error? then callback 500
								else callback()


	login: (socket, data, callback) =>
		if not data?.email? or not data?.password?
			callback 400
		else
			@modelRpcConnection.users.read.get_user data.email, (error, user) =>
				if error? then callback 401
				else
					passwordHash = @passwordHasher.hashPasswordWithSalt data.password, user.salt
					if passwordHash isnt user.password_hash
						callback 401
					else
						socket.session.userId = user.id
						socket.session.email = user.email
						socket.session.firstName = user.first_name
						socket.session.lastName = user.last_name
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
