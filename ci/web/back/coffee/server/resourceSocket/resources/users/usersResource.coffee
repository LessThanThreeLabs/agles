assert = require 'assert'

Resource = require '../resource'
PasswordHasher = require './passwordHasher'
AccountInformationValidator = require './accountInformationValidator'
ResetPasswordEmailer = require './resetPasswordEmailer'
CreateAccountHandler = require './create/createAccountHandler'
LoginHandler = require './login/loginHandler'

UsersCreateHandler = require './handlers/usersCreateHandler'
UsersUpdateHandler = require './handlers/usersUpdateHandler'
UsersReadHandler = require './handlers/usersReadHandler'


exports.create = (configurationParams, stores, modelConnection) ->
	passwordHasher = PasswordHasher.create()
	accountInformationValidator = AccountInformationValidator.create()
	resetPasswordEmailer = ResetPasswordEmailer.create configurationParams

	createHandler = UsersCreateHandler.create modelConnection.rpcConnection, passwordHasher, accountInformationValidator
	readHandler = UsersReadHandler.create modelConnection.rpcConnection
	updateHandler = UsersUpdateHandler.create modelConnection.rpcConnection, passwordHasher, accountInformationValidator, resetPasswordEmailer
	return new UsersResource configurationParams, stores, modelConnection, createHandler, readHandler, updateHandler


class UsersResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @createHandler, @readHandler, @updateHandler) ->
		super configurationParams, stores, modelConnection
		assert.ok @createHandler?
		assert.ok @readHandler?
		assert.ok @updateHandler?


	create: (socket, data, callback) =>
		@_call @createHandler, socket, data, callback


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	update: (socket, data, callback) =>
		@_call @updateHandler, socket, data, callback


	subscribe: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		if not data.method? and data.args?.id?
			callback 400
		else
			console.log 'need to make sure this user is allowed to receive updates for id ' + data.args.id
			eventName = @modelConnection.eventConnection.users.registerForEvents socket, data.args.id, data.method
			if eventName? then callback null, eventName
			else callback 400


	unsubscribe: (socket, data, callback) =>
		@modelConnection.eventConnection.users.unregisterForEvents socket, data.id
		callback null, 'ok' if callback?
