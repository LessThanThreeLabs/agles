assert = require 'assert'

UsersResource = require './resources/users/usersResource'
ChangesResource = require './resources/changes/changesResource'
BuildOutputsResource = require './resources/buildOutputs/buildOutputsResource'
RepositoriesResource = require './resources/repositories/repositoriesResource'


exports.create = (configurationParams, stores, modelConnection) ->
	resources =
		users: UsersResource.create configurationParams, stores, modelConnection
		repositories: RepositoriesResource.create configurationParams, stores, modelConnection
		changes: ChangesResource.create configurationParams, stores, modelConnection
		buildOutputs: BuildOutputsResource.create configurationParams, stores, modelConnection
	return new ResourceRouter resources


class ResourceRouter
	constructor: (@resources) ->
		assert.ok @resources?
		for resourceName, resource of @resources
			assert.ok resource?


	bindToResources: (socket) ->
		for resourceName, resource of @resources
			@_bindToResource socket, resourceName, resource


	_bindToResource: (socket, noun, resource) ->
		verbs = (key for key in Object.keys(resource) when typeof resource[key] is 'function')
		for verb in verbs
			@_bindToResourceFunction socket, noun, verb, resource


	_bindToResourceFunction: (socket, noun, verb, resource) ->
		socket.on noun + '.' + verb, (data, callback) ->
			callback ?= () ->
			resource[verb] socket, data, callback
