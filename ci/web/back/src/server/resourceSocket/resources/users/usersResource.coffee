assert = require 'assert'

Resource = require '../resource'
PasswordHasher = require './passwordHasher'
AccountInformationValidator = require './accountInformationValidator'
InviteUserEmailer = require './inviteUserEmailer'
ResetPasswordEmailer = require './resetPasswordEmailer'

UsersCreateHandler = require './handlers/usersCreateHandler'
UsersReadHandler = require './handlers/usersReadHandler'
UsersUpdateHandler = require './handlers/usersUpdateHandler'
UsersDeleteHandler = require './handlers/usersDeleteHandler'


exports.create = (configurationParams, stores, modelConnection) ->
	passwordHasher = PasswordHasher.create()
	accountInformationValidator = AccountInformationValidator.create()
	inviteUserEmailer = InviteUserEmailer.create configurationParams
	resetPasswordEmailer = ResetPasswordEmailer.create configurationParams

	createHandler = UsersCreateHandler.create stores, modelConnection.rpcConnection, passwordHasher, accountInformationValidator, inviteUserEmailer
	readHandler = UsersReadHandler.create stores, modelConnection.rpcConnection
	updateHandler = UsersUpdateHandler.create modelConnection.rpcConnection, passwordHasher, accountInformationValidator, resetPasswordEmailer
	deleteHandler = UsersDeleteHandler.create modelConnection.rpcConnection
	return new UsersResource configurationParams, stores, modelConnection, createHandler, readHandler, updateHandler, deleteHandler


class UsersResource extends Resource
	constructor: (configurationParams, stores, modelConnection, @createHandler, @readHandler, @updateHandler, @deleteHandler) ->
		super configurationParams, stores, modelConnection
		assert.ok @createHandler?
		assert.ok @readHandler?
		assert.ok @updateHandler?
		assert.ok @deleteHandler?


	create: (socket, data, callback) =>
		@_call @createHandler, socket, data, callback


	read: (socket, data, callback) =>
		@_call @readHandler, socket, data, callback


	update: (socket, data, callback) =>
		@_call @updateHandler, socket, data, callback


	delete: (socket, data, callback) =>
		@_call @deleteHandler, socket, data, callback


	subscribe: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		if typeof data.method isnt 'string' or typeof data.args?.id isnt 'number'
			callback 400
		else
			@modelConnection.rpcConnection.users.read.can_hear_user_events userId, data.args.id, (error, permitted) =>
				if error? or not permitted then callback 403
				else
					eventName = @modelConnection.eventConnection.users.registerForEvents socket, data.args.id, data.method
					if eventName? then callback null, eventName
					else callback 400


	unsubscribe: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		if typeof data.method isnt 'string' or typeof data.args?.id isnt 'number'
			callback 400
		else
			success = @modelConnection.eventConnection.users.unregisterForEvents socket, data.args.id, data.method
			if success then callback()
			else callback 400
