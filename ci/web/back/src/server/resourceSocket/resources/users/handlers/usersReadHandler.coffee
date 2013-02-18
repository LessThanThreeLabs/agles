assert = require 'assert'

Handler = require '../../handler'


exports.create = (stores, modelRpcConnection) ->
	return new UsersReadHandler stores, modelRpcConnection


class UsersReadHandler extends Handler
	constructor: (@stores, modelRpcConnection) ->
		super modelRpcConnection
		assert.ok @stores?


	getSshKeys: (socket, data, callback) =>
		sanitizeResult = (key) ->
			id: key.id
			alias: key.alias
			timestamp: key.timestamp

		userId = socket.session.userId
		if not userId?
			callback 403
		else
			@modelRpcConnection.users.read.get_ssh_keys userId, (error, keys) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, (sanitizeResult key for key in keys)


	getEmailFromToken: (socket, data, callback) =>
		if not data?.token?
			callback 400
		else
			@stores.createAccountStore.getAccount data.token, (error, account) =>
				console.log error
				if error? then callback 500
				else callback null, account.email
