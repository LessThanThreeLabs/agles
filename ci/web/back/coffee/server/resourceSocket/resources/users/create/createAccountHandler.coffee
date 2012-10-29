assert = require 'assert'
crypto = require 'crypto'

CreateAccountEmailer = require './createAccountEmailer'


exports.create = (configurationParams, createAccountStore, modelRpcConnection, accountInformationValidator) ->
	createAccountEmailer = CreateAccountEmailer.create configurationParams.createAccount.email, configurationParams.domain
	return new CreateAccountHandler configurationParams, createAccountStore, modelRpcConnection, accountInformationValidator, createAccountEmailer


class CreateAccountHandler
	constructor: (@configurationParams, @createAccountStore, @modelRpcConnection, @accountInformationValidator, @createAccountEmailer) ->
		assert.ok @configurationParams? and @createAccountStore? and @modelRpcConnection? and @accountInformationValidator? and @createAccountEmailer?


	handleRequest: (socket, data, callback) =>
		errors = @_getErrors socket, data

		if Object.keys(errors).length isnt 0
			callback errors, false
		else
			callback null, true
			# @_performRequest socket, data, callback


	_getErrors: (socket, data, callback) =>
		errors = {}

		if @accountInformationValidator.isEmailValid(data.email) isnt 'ok'
			console.log 'bad email: ' + data.email
			errors.email = @accountInformationValidator.isEmailValid data.email

		if @accountInformationValidator.isPasswordValid(data.password) isnt 'ok'
			errors.password = @accountInformationValidator.isPasswordValid data.password
		
		if @accountInformationValidator.isFirstNameValid(data.firstName) isnt 'ok'
			errors.firstName = @accountInformationValidator.isFirstNameValid data.firstName
		
		if @accountInformationValidator.isLastNameValid(data.lastName) isnt 'ok'
			errors.lastName = @accountInformationValidator.isLastNameValid data.lastName
		
		# check if the email is already taken last, since it's the most expensive
		if Object.keys(errors) is 0 and @_checkIfEmailAlreadyExists data.email
			errors.email = 'Email is already in use'

		return errors


	_checkIfEmailAlreadyExists: (email) =>
		console.log 'need to check if email aleady exists in database...'
		return false


	_performRequest: (socket, data, callback) =>
		@_createKeyAndAccount data, (error, key, account) =>
			callback 'Something went wrong...' if error?

			@stores.createAccountStore.addAccount key, account
			@createAccountEmailer.sendEmailToUser data.firstName, data.lastName, data.email, key
					
			callback null, true


	_createKeyAndAccount: (data, callback) =>
		crypto.randomBytes 24, (error, buffer) =>
			callback error if error?

			key = buffer.toString('hex').substr 0, 16
			salt = buffer[8...24]

			callback null, key,
				email: data.email
				salt: salt
				passwordHash: crypto.createHash('sha512').update(salt).update(data.password, 'utf8').digest()
				firstName: data.firstName
				lastName: data.lastName
