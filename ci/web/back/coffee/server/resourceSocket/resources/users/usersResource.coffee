assert = require 'assert'

Resource = require '../resource'
PasswordHasher = require './passwordHasher'
AccountInformationValidator = require './accountInformationValidator'
CreateAccountHandler = require './create/createAccountHandler'
LoginHandler = require './login/loginHandler'


exports.create = (configurationParams, stores, modelRpcConnection) ->
	passwordHasher = PasswordHasher.create()
	accountInformationValidator = AccountInformationValidator.create()
	createAccountHandler = CreateAccountHandler.create configurationParams, stores.createAccountStore, modelRpcConnection, passwordHasher, accountInformationValidator
	loginHandler = LoginHandler.create configurationParams, modelRpcConnection, passwordHasher
	return new UsersResource configurationParams, stores, modelRpcConnection, createAccountHandler, loginHandler


class UsersResource extends Resource
	constructor: (configurationParams, stores, modelRpcConnection, @createAccountHandler, @loginHandler) ->
		assert.ok @createAccountHandler? and @loginHandler?
		super configurationParams, stores, modelRpcConnection


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
