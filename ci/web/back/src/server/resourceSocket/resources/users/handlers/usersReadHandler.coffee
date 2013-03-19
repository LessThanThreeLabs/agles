assert = require 'assert'

Handler = require '../../handler'


exports.create = (stores, modelRpcConnection) ->
	return new UsersReadHandler stores, modelRpcConnection


class UsersReadHandler extends Handler
	constructor: (@stores, modelRpcConnection) ->
		super modelRpcConnection
		assert.ok @stores?


	getAllUsers: (socket, data, callback) =>
		sanitizeResult = (user) ->
			id: user.id
			email: user.email
			firstName: user.first_name
			lastName: user.last_name
			isAdmin: user.admin
			timestamp: user.created * 1000

		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.users.read.get_all_users userId, (error, users) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, (sanitizeResult user for user in users)


	getSshKeys: (socket, data, callback) =>
		sanitizeResult = (key) ->
			id: key.id
			alias: key.alias
			timestamp: key.timestamp * 1000

		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.users.read.get_ssh_keys userId, (error, keys) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, (sanitizeResult key for key in keys)

