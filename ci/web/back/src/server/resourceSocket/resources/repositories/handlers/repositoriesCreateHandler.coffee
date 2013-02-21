assert = require 'assert'
createKeys = require 'rsa-json'

Handler = require '../../handler'


exports.create = (stores, modelRpcConnection, sshKeyPairGenerator) ->
	return new RepositoriesCreateHandler stores, modelRpcConnection, sshKeyPairGenerator


class RepositoriesCreateHandler extends Handler
	constructor: (@stores, modelRpcConnection, @sshKeyPairGenerator) ->
		super modelRpcConnection
		assert.ok @stores?
		assert.ok @sshKeyPairGenerator?


	createRepository: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId? or not socket.session?.isAdmin
			callback 403
		else if not data?.name? or not data?.forwardUrl?
			callback 400
		else
			@stores.createRepositoryStore.getRepository data.name, (error, repository) =>
				if error? then callback 500
				else
					@modelRpcConnection.repos.create.create_repo userId, data.name, data.forwardUrl, repository.keyPair, (error, repositoryId) =>
						if error?.type is 'InvalidPermissionsError' then callback 403
						else if error? then callback 500
						else callback null, repositoryId


	getSshPublicKey: (socket, data, callback) =>
		userId = socket.session.userId
		if not userId? or not socket.session?.isAdmin
			callback 403
		else if not data?.name?
			callback 400
		else
			@sshKeyPairGenerator.createKeyPair (error, keyPair) =>
				if error? then callback 500
				else
					@stores.createRepositoryStore.addRepository data.name, keyPair: keyPair
					callback null, keyPair.public
