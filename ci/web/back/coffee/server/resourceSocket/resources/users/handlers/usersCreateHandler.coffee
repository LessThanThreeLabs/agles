assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, passwordHasher, accountInformationValidator) ->
	return new UsersCreateHandler modelRpcConnection, passwordHasher, accountInformationValidator


class UsersCreateHandler extends Handler

	constructor: (modelRpcConnection, @passwordHasher, @accountInformationValidator) ->
		super modelRpcConnection
		assert.ok modelRpcConnection? 
		assert.ok @passwordHasher?
		assert.ok @accountInformationValidator?


	create: (socket, data, callback) =>
		if not data.email? or not data.password? or not data.firstName? or not data.lastName? or not data.rememberMe?
			callback 400
		else
			errors = {}
			if not @accountInformationValidator.isValidFirstName data.firstName
				errors.firstName = @accountInformationValidator.getInvalidFirstNameString()
			if not @accountInformationValidator.isValidLastName data.lastName 
				errors.lastName = @accountInformationValidator.getInvalidLastNameString()
			if not @accountInformationValidator.isValidPassword data.password
				errors.password = @accountInformationValidator.getInvalidPasswordString()

			if Object.keys(errors).length isnt 0
				callback errors
				return

			@passwordHasher.getPasswordHash data.password, (passwordHashError, passwordHashResult) =>
				if passwordHashError?
					callback 500
				else
					@modelConnection.rpcConnection.users.create.create_user 
						data.email, data.firstName, data.lastName, passwordHashResult.hashedPassword, passwordHashResult.salt,
						(error, userId) =>
							if error?.type is 'UserExistsError' then callback 'User already exists'
							else if error? then callback 500
							else callback 'ok'
