assert = require 'assert'

UsersResource = require './resources/users/usersResource'
OrganizationsResource = require './resources/organizations/organizationsResource'
ChangesResource = require './resources/changes/changesResource'
BuildsResource = require './resources/builds/buildsResource'
BuildOutputsResource = require './resources/buildOutputs/buildOutputsResource'
RepositoriesResource = require './resources/repositories/repositoriesResource'


exports.create = (configurationParams, stores, modelConnection) ->
	usersResource = UsersResource.create configurationParams, stores, modelConnection
	organizationsResource = OrganizationsResource.create configurationParams, stores, modelConnection
	changesResource = ChangesResource.create configurationParams, stores, modelConnection
	buildsResource = BuildsResource.create configurationParams, stores, modelConnection
	buildOutputsResource = BuildOutputsResource.create configurationParams, stores, modelConnection
	repositoriesResource = RepositoriesResource.create configurationParams, stores, modelConnection
	return new ResourceRouter usersResource, organizationsResource, changesResource, buildsResource, buildOutputsResource, repositoriesResource


class ResourceRouter
	constructor: (@usersResource, @organizationsResource, @changesResource, @buildsResource, @buildOutputsResource, @repositoriesResource) ->


	bindToResources: (socket) ->
		@_bindToResource socket, 'users', @usersResource
		@_bindToResource socket, 'organizations', @organizationsResource
		@_bindToResource socket, 'changes', @changesResource
		@_bindToResource socket, 'builds', @buildsResource
		@_bindToResource socket, 'buildOutputs', @buildOutputsResource
		@_bindToResource socket, 'repos', @repositoriesResource


	_bindToResource: (socket, name, resource) ->
		allowedActions = (key for key in Object.keys(resource) when typeof resource[key] is 'function')
		for action in allowedActions
			@_bindToResourceFunction socket, name, action, resource


	_bindToResourceFunction: (socket, name, action, resource) ->
		eventName = name + ':' + action
		socket.on eventName, (data, callback) ->
			# if not socket.session.user?
			# 	callback 'No user associated with resource request'
			# else
			socket.session.user = 'fake user'
			resource[action] socket, data, callback
