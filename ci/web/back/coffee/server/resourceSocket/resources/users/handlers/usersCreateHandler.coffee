assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, createAccountHandler, accountInformationValidator) ->
	return new UsersCreateHandler modelRpcConnection, createAccountHandler, accountInformationValidator


class UsersCreateHandler extends Handler

	constructor: (modelRpcConnection, @createAccountHandler, @accountInformationValidator) ->
		assert.ok modelRpcConnection? and @createAccountHandler? and @accountInformationValidator?
		super modelRpcConnection


	# -- GIVEN --
	# data =
	#   email: <string>
	#   password: <string>
	#   firstName: <string>
	#   lastName: <string>
	# -- RETURNED --
	# errors =
	#   email: <string>
	#   password: <string>
	#   firstName: <string>
	#   lastName: <string>
	# result = <boolean>
	default: (socket, data, callback) =>
		if data.email? and data.password? and data.rememberMe? and data.firstName? and data.lastName?

			errors = {}
			if not @accountInformationValidator.isValidFirstName data.firstName
				errors.firstName = @accountInformationValidator.getInvalidFirstNameString()
			if not @accountInformationValidator.isValidLastName data.lastName 
				errors.lastName = @accountInformationValidator.getInvalidLastNameString()
			# if not @accountInformationValidator.isValidEmail data.email
				# errors.email = @accountInformationValidator.getInvalidEmailString()
			if not @accountInformationValidator.isValidPassword data.password
				errors.password = @accountInformationValidator.getInvalidPasswordString()

			if Object.keys(errors).length != 0
				callback errors
				return

			@createAccountHandler.handleRequest socket, data, callback
		else
			callback 'parsing error'
