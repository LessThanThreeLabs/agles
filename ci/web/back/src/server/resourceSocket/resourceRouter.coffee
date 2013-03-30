assert = require 'assert'

UsersResource = require './resources/users/usersResource'
ChangesResource = require './resources/changes/changesResource'
BuildConsolesResource = require './resources/buildConsoles/buildConsolesResource'
RepositoriesResource = require './resources/repositories/repositoriesResource'
SystemSettingsResource = require './resources/systemSettings/systemSettingsResource'


exports.create = (configurationParams, stores, modelConnection, mailer) ->
	resources =
		users: UsersResource.create configurationParams, stores, modelConnection, mailer
		repositories: RepositoriesResource.create configurationParams, stores, modelConnection, mailer
		changes: ChangesResource.create configurationParams, stores, modelConnection, mailer
		buildConsoles: BuildConsolesResource.create configurationParams, stores, modelConnection, mailer
		systemSettings: SystemSettingsResource.create configurationParams, stores, modelConnection, mailer
	return new ResourceRouter configurationParams, resources


class ResourceRouter
	constructor: (@configurationParams, @resources) ->
		assert.ok @configurationParams
		assert.ok @resources?
		for resourceName, resource of @resources
			assert.ok resource?


	bindToResources: (socket) =>
		for resourceName, resource of @resources
			@_bindToResource socket, resourceName, resource


	_bindToResource: (socket, noun, resource) =>
		verbs = (key for key in Object.keys(resource) when typeof resource[key] is 'function')
		for verb in verbs
			@_bindToResourceFunction socket, noun, verb, resource


	_bindToResourceFunction: (socket, noun, verb, resource) =>
		socket.on noun + '.' + verb, (data, callback) =>
			callback ?= () ->

			if process.env.NODE_ENV is 'development'
				setTimeout (() -> resource[verb] socket, data, callback), @configurationParams.developmentAddedLatency
			else
				resource[verb] socket, data, callback
