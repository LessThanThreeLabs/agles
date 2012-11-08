assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, createAccountHandler) ->
	return new UsersCreateHandler modelRpcConnection, createAccountHandler


class UsersCreateHandler extends Handler
	constructor: (modelRpcConnection, @createAccountHandler) ->
		assert.ok modelRpcConnection? and @createAccountHandler?
		super modelRpcConnection


	default: (socket, data, callback) =>
		if data.email? and data.password? and data.rememberMe? and data.firstName? and data.lastName?
			@createAccountHandler.handleRequest socket, data, callback
		else
			callback 'Parsing error'
