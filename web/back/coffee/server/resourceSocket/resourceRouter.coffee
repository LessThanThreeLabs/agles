assert = require 'assert'

OrganizationsResource = require './resources/organizationsResource'
BuildsResource = require './resources/buildsResource'
RepositoriesResource = require './resources/repositoriesResource'


exports.create = (modelConnection) ->
	organizationsResource = OrganizationsResource.create modelConnection
	buildsResource = BuildsResource.create modelConnection
	repositoriesResource = RepositoriesResource.cerate modelConnection
	return new ResourceRouter organizationsResource, buildsResource


class ResourceRouter
	constructor: (@organizationsResource, @buildsResource) ->
		@allowedActions = ['create', 'read', 'update', 'delete']
		assert.ok @_checkResource @organizationsResource
		assert.ok @_checkResource @buildsResource


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
			fn = resource[action] socket.session, data, callback
