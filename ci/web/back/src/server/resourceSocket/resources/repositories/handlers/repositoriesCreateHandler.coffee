assert = require 'assert'

Handler = require '../../handler'


exports.create = (modelRpcConnection, sshKeyGenerator) ->
	return new RepositoriesCreateHandler modelRpcConnection, sshKeyGenerator


class RepositoriesCreateHandler extends Handler
	constructor: (modelRpcConnection, @sshKeyGenerator) ->
		super modelRpcConnection
		assert.ok @sshKeyGenerator?


	create: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId?
			callback 403
		else if not data?.name? or not data?.forwardUrl?
			callback 400
		else
			@modelRpcConnection.repos.create.create_repo userId, data.name, data.forwardUrl, (error, repositoryId) =>
				if error?.type is 'InvalidPermissionsError' then callback 403
				else if error? then callback 500
				else callback null, repositoryId


	getSshPublicKey: (socket, data, callback) =>
		@sshKeyGenerator.generateKey (error, keyPair) =>
			console.error error
			console.log keyPair
