assert = require 'assert'


exports.create = (configurationParams, modelRpcConnection) ->
	return new LoginHandler configurationParams, modelRpcConnection


class LoginHandler
	constructor: (@configurationParams, @modelRpcConnection) ->
		assert.ok @configurationParams? and @modelRpcConnection?


	handleRequest: (socket, data, callback) =>
		console.log 'need to handle login'
		callback null, 'some data here...'
		