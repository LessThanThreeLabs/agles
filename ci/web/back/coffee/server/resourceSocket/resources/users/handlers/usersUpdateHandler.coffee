assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, loginHandler) ->
	return new UsersUpdateHandler modelRpcConnection, loginHandler


class UsersUpdateHandler extends Handler
	constructor: (modelRpcConnection, @loginHandler) ->
		assert.ok modelRpcConnection? and @loginHandler?
		super modelRpcConnection


	default: (socket, data, callback) =>
		if data.email? and data.password? and data.rememberMe?
			@loginHandler.handleRequest socket, data, callback
		else
			callback 'Parsing error'
