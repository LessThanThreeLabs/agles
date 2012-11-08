assert = require 'assert'

Resource = require '../resource'
PasswordHasher = require './passwordHasher'
AccountInformationValidator = require './accountInformationValidator'
CreateAccountHandler = require './create/createAccountHandler'
LoginHandler = require './login/loginHandler'


exports.create = (configurationParams, stores, modelConnection) ->
	passwordHasher = PasswordHasher.create()
	accountInformationValidator = AccountInformationValidator.create()
	createAccountHandler = CreateAccountHandler.create configurationParams, stores.createAccountStore, modelConnection.rpcConnection, passwordHasher, accountInformationValidator
	loginHandler = LoginHandler.create configurationParams, modelConnection.rpcConnection, passwordHasher
	return new UsersResource configurationParams, stores, modelConnection, createAccountHandler, loginHandler


class UsersResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @createAccountHandler, @loginHandler) ->
		assert.ok @createAccountHandler? and @loginHandler?
		super configurationParams, stores, modelConnection


	create: (socket, data, callback) =>
		if data.email? and data.password? and data.rememberMe? and data.firstName? and data.lastName?
			@createAccountHandler.handleRequest socket, data, callback
		else
			callback 'Parsing error'


	update: (socket, data, callback) =>
		if data.email? and data.password? and data.rememberMe?
			@loginHandler.handleRequest socket, data, callback
		else
			callback 'Parsing error'
