assert = require 'assert'

OrganizationsResource = require './resources/organizationsResource'
BuildsResource = require './resources/buildsResource'
RepositoriesResource = require './resources/repositoriesResource'


exports.create = (modelRpcConnection) ->
	organizationsResource = OrganizationsResource.create modelRpcConnection
	buildsResource = BuildsResource.create modelRpcConnection
	repositoriesResource = RepositoriesResource.create modelRpcConnection
	return new ResourceRouter organizationsResource, buildsResource, repositoriesResource


class ResourceRouter
	constructor: (@organizationsResource, @buildsResource, @repositoriesResource) ->
		@allowedActions = ['create', 'read', 'update', 'delete', 'subscribe']
		assert.ok @_checkResource @organizationsResource
		assert.ok @_checkResource @buildsResource
		assert.ok @_checkResource @repositoriesResource


	_checkResource: (resource) ->
		for action in @allowedActions
			assert.ok typeof resource[action] == 'function'


	bindToResources: (socket) ->
		@_bindToResource socket, 'organizations', @organizationsResource
		@_bindToResource socket, 'builds', @buildsResource
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
