assert = require 'assert'

Handler = require '../../handler'


exports.create = (stores, modelRpcConnection) ->
	return new UsersReadHandler stores, modelRpcConnection


class UsersReadHandler extends Handler
	constructor: (@stores, modelRpcConnection) ->
		super modelRpcConnection
		assert.ok @stores?


	getAllUsers: (socket, data, callback) =>
		createFakeUser = (number) ->
			id: number
			email: "#{number}@email.com"
			firstName: "hello#{number}"
			lastName: "there#{number}"
			timestamp: Math.floor(Math.random() * 1000000000000)

		userId = socket.session.userId
		if not userId? or not socket.session?.isAdmin
			callback 403
		else
			callback null, (createFakeUser number for number in [0..100])


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

