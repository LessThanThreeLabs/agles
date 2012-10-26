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
		if @accountInformationValidator.isEmailValid data.email is not 'ok'
			callback @accountInformationValidator.isEmailValid data.email
		else if @accountInformationValidator.isPasswordValid data.password is not 'ok'
			callback @accountInformationValidator.isPasswordValid data.password
		else if @accountInformationValidator.isFirstNameValid data.firstName is not 'ok'
			callback @accountInformationValidator.isFirstNameValid data.firstName
		else if @accountInformationValidator.isLastNameValid data.lastName is not 'ok'
			callback @accountInformationValidator.isLastNameValid data.lastName
		else if @_checkIfEmailAlreadyExists data.email
			callback 'Email is already in use'
		else
			@_performCreateAccountRequest socket, data, callback


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
