assert = require 'assert'
crypto = require 'crypto'

CreateAccountEmailer = require './createAccountEmailer'


exports.create = (configurationParams, createAccountStore, modelRpcConnection, passwordHasher, accountInformationValidator) ->
	createAccountEmailer = CreateAccountEmailer.create configurationParams
	return new CreateAccountHandler configurationParams, createAccountStore, modelRpcConnection, passwordHasher, accountInformationValidator, createAccountEmailer


class CreateAccountHandler
	constructor: (@configurationParams, @createAccountStore, @modelRpcConnection, @passwordHasher, @accountInformationValidator, @createAccountEmailer) ->
		assert.ok @configurationParams? 
		assert.ok @createAccountStore?
		assert.ok @modelRpcConnection?
		assert.ok @passwordHasher?
		assert.ok @accountInformationValidator?
		assert.ok @createAccountEmailer?


	handleRequest: (socket, data, callback) =>
		errors = @_getErrors socket, data

		if Object.keys(errors).length isnt 0
			callback errors, false
		else
			@_performRequest socket, data, callback


	_getErrors: (socket, data, callback) =>
		errors = {}

		if not @accountInformationValidator.isValidEmail data.email
			errors.email = @accountInformationValidator.getInvalidEmailString()

		if not @accountInformationValidator.isValidPassword data.password
			errors.password = @accountInformationValidator.getInvalidPasswordString()
		
		if not @accountInformationValidator.isValidFirstName data.firstName
			errors.firstName = @accountInformationValidator.getInvalidFirstNameString()
		
		if not @accountInformationValidator.isValidLastName data.lastName
			errors.lastName = @accountInformationValidator.getInvalidLastNameString()
		
		# check if the email is already taken last, since it's the most expensive
		if Object.keys(errors) is 0 and @_checkIfEmailAlreadyExists data.email
			errors.email = 'Email is already in use'

		return errors


	_checkIfEmailAlreadyExists: (email) =>
		console.log 'need to check if email aleady exists in database...'
		return false


	_performRequest: (socket, data, callback) =>
		@_createKeyAndAccount data, (error, key, account) =>
			if error?
				callback 'Something went wrong...'
				return

			@createAccountStore.addAccount key, account
			@createAccountEmailer.sendEmailToUser data.firstName, data.lastName, data.email, key
			
			callback null, true


	_createKeyAndAccount: (data, callback) =>
		await
			crypto.randomBytes 8, defer keyError, keyBuffer
			@passwordHasher.getPasswordHash data.password, defer passwordHashError, passwordHashInfo

		if keyError? 
			callback keyError
		else if passwordHashError? 
			callback passwordHashError
		else
			key = keyBuffer.toString('hex')
			salt = passwordHashInfo.salt
			passwordHash = passwordHashInfo.passwordHash
			userToCreate = 
				email: data.email
				salt: salt
				passwordHash: passwordHash
				firstName: data.firstName
				lastName: data.lastName
				rememberMe: data.rememberMe

			callback null, key, userToCreate
