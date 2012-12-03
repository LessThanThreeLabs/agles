assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection) ->
	return new RepositoriesSubscribeHandler modelRpcConnection


class RepositoriesSubscribeHandler extends Handler
	
	default: (socket, data, callback) =>
		console.log 'need to check that the user is allowed to register for these events...'
		@modelConnection.eventConnection.repositories.registerForEvents socket, data.id
		callback null, 'Ok'
