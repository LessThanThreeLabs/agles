assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, loginHandler) ->
	return new UsersUpdateHandler modelRpcConnection, loginHandler


class UsersUpdateHandler extends Handler
	constructor: (modelRpcConnection, @loginHandler) ->
		assert.ok modelRpcConnection? and @loginHandler?
		super modelRpcConnection


	# -- GIVEN --
	# data =
	#   email: <string>
	#   password: <string>
	# -- RETURNED --
	# errors = UNDEFINED RIGHT NOW
	# result =
	#   firstName: <string>
	#   lastName: <string>
	login: (socket, data, callback) =>
		if data.email? and data.password? and data.rememberMe?
			@loginHandler.handleRequest socket, data, callback
		else
			callback 'Malformed request.'
