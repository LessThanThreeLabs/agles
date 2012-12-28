assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new UsersReadHandler modelRpcConnection


class UsersReadHandler extends Handler
	
	constructor: (modelRpcConnection) ->
		assert.ok modelRpcConnection?
		super modelRpcConnection


	default: (socket, data, callback) =>
		userId = socket.session.userId
		@modelRpcConnection.users.read.get_user_from_id userId, (error, user) =>
			if error?
				if error.type is 'InvalidPermissionsError' then callback 403
				else callback 'unable to get user data'
			else
				callback @_sanitize user


	getSshKeys: (socket, data, callback) =>
		userId = socket.session.userId
		@modelRpcConnection.users.read.get_ssh_keys userId, (error, keys) =>
			if error?
				console.error error
				callback error
			else
				sanitizedKeys = (@_sanitizeSshKey key for key in keys)
				callback null, sanitizedKeys


	_sanitizeSshKey: (key) =>
		userId: key.user_id
		alias: key.alias
		sshKey: key.ssh_key
		dateAdded: "blah"


	_sanitize: (user) =>
		id: user.id
		firstName: user.first_name
		lastName: user.last_name
		email: user.email