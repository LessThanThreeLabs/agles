assert = require 'assert'

Resource = require '../resource'
PasswordHasher = require './passwordHasher'
AccountInformationValidator = require './accountInformationValidator'
CreateAccountHandler = require './create/createAccountHandler'
LoginHandler = require './login/loginHandler'

UsersCreateHandler = require './handlers/usersCreateHandler'
UsersUpdateHandler = require './handlers/usersUpdateHandler'
UsersReadHandler = require './handlers/usersReadHandler'

exports.create = (configurationParams, stores, modelConnection) ->
	passwordHasher = PasswordHasher.create()
	accountInformationValidator = AccountInformationValidator.create()
	createAccountHandler = CreateAccountHandler.create configurationParams, stores.createAccountStore, modelConnection.rpcConnection, passwordHasher, accountInformationValidator
	loginHandler = LoginHandler.create configurationParams, modelConnection.rpcConnection, passwordHasher
	createHandler = UsersCreateHandler.create modelConnection.rpcConnection, createAccountHandler
	readHandler = UsersReadHandler.create modelConnection.rpcConnection
	updateHandler = UsersUpdateHandler.create modelConnection.rpcConnection, loginHandler, accountInformationValidator
	return new UsersResource configurationParams, stores, modelConnection, createHandler, readHandler, updateHandler


class UsersResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @createHandler, @readHandler, @updateHandler) ->
		assert.ok @createHandler?
		assert.ok @readHandler?
		assert.ok @updateHandler?

		super configurationParams, stores, modelConnection


	create: (socket, data, callback) =>
		@_call @createHandler, socket, data, callback


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	update: (socket, data, callback) =>
		@_call @updateHandler, socket, data, callback
