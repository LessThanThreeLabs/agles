assert = require 'assert'

UsersResource = require './resources/users/usersResource'
OrganizationsResource = require './resources/organizations/organizationsResource'
BuildsResource = require './resources/builds/buildsResource'
BuildOutputsResource = require './resources/buildOutputs/buildOutputsResource'
RepositoriesResource = require './resources/repositories/repositoriesResource'


exports.create = (configurationParams, modelRpcConnection) ->
	usersResource = UsersResource.create configurationParams, modelRpcConnection
	organizationsResource = OrganizationsResource.create configurationParams, modelRpcConnection
	buildsResource = BuildsResource.create configurationParams, modelRpcConnection
	buildOutputsResource = BuildOutputsResource.create configurationParams, modelRpcConnection
	repositoriesResource = RepositoriesResource.create configurationParams, modelRpcConnection
	return new ResourceRouter usersResource, organizationsResource, buildsResource, buildOutputsResource, repositoriesResource


class ResourceRouter
	constructor: (@usersResource, @organizationsResource, @buildsResource, @buildOutputsResource, @repositoriesResource) ->
		@allowedActions = ['create', 'read', 'update', 'delete', 'subscribe']
		assert.ok @_checkResource @usersResource
		assert.ok @_checkResource @organizationsResource
		assert.ok @_checkResource @buildsResource
		assert.ok @_checkResource @buildOutputsResource
		assert.ok @_checkResource @repositoriesResource


	_checkResource: (resource) ->
		for action in @allowedActions
			assert.ok typeof resource[action] == 'function'


	bindToResources: (socket) ->
		@_bindToResource socket, 'users', @usersResource
		@_bindToResource socket, 'organizations', @organizationsResource
		@_bindToResource socket, 'builds', @buildsResource
		@_bindToResource socket, 'buildOutputs', @buildOutputsResource
		@_bindToResource socket, 'repositories', @repositoriesResource


	_bindToResource: (socket, name, resource) ->
		for action in @allowedActions
			@_bindToResourceFunction socket, name, action, resource


	_bindToResourceFunction: (socket, name, action, resource) ->
		eventName = name + ':' + action
		socket.on eventName, (data, callback) ->
			# if not socket.session.user?
			# 	callback 'No user associated with resource request'
			# else
				socket.session.user = 'fake user'
				resource[action] socket, data, callback
