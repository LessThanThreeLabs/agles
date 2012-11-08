assert = require 'assert'

Resource = require '../resource'
PasswordHasher = require './passwordHasher'
AccountInformationValidator = require './accountInformationValidator'
CreateAccountHandler = require './create/createAccountHandler'
LoginHandler = require './login/loginHandler'

UsersCreateHandler = require './handlers/usersCreateHandler'
UsersUpdateHandler = require './handlers/usersUpdateHandler'

exports.create = (configurationParams, stores, modelConnection) ->
	passwordHasher = PasswordHasher.create()
	accountInformationValidator = AccountInformationValidator.create()
	createAccountHandler = CreateAccountHandler.create configurationParams, stores.createAccountStore, modelConnection.rpcConnection, passwordHasher, accountInformationValidator
	loginHandler = LoginHandler.create configurationParams, modelConnection.rpcConnection, passwordHasher
	createHandler = UsersCreateHandler.create modelConnection.rpcConnection, createAccountHandler
	updateHandler = UsersUpdateHandler.create modelConnection.rpcConnection, loginHandler
	return new UsersResource configurationParams, stores, modelConnection, createHandler, updateHandler


class UsersResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @createHandler, @updateHandler) ->
		assert.ok @createHandler? and @updateHandler?
		super configurationParams, stores, modelConnection


	create: (socket, data, callback) =>
		@_call @createHandler, socket, data, callback


	update: (socket, data, callback) =>
		@_call @updateHandler, socket, data, callback
