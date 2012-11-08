assert = require 'assert'

ResourceEventConnection = require './resourceEventConnection'

UserEventHandler = require './handlers/userEventHandler'
OrganizationEventHandler = require './handlers/organizationEventHandler'
BuildEventHandler = require './handlers/buildEventHandler'
BuildOutputEventHandler = require './handlers/buildOutputEventHandler'
RepositoryEventHandler = require './handlers/repositoryEventHandler'


exports.create = (configurationParams, connection) ->
	return new EventConnection configurationParams, connection


class EventConnection
	constructor: (@configurationParams, @connection) ->
		assert.ok @configurationParams? and @connection?


	connect: (callback) ->
		@connection.exchange @configurationParams.events.exchange, type: 'direct', (@exchange) =>
			assert.ok @exchange?
			callback()


	setSockets: (@sockets, callback) ->
		assert.ok sockets? and @exchange?
		@_createHandlers callback


	_createHandlers: (callback) =>
		@users = UserEventHandler.create @sockets
		@organizations = OrganizationEventHandler.create @sockets
		@builds = BuildEventHandler.create @sockets
		@buildOutputs = BuildOutputEventHandler.create @sockets
		@repositories = RepositoryEventHandler.create @sockets

		@_connectHandlers callback


	_connectHandlers: (callback) =>
		queueNamePrefix = @configurationParams.events.queueNamePrefix

		@userEventConnection = ResourceEventConnection.create @connection, 
			@exchange, 'users', queueNamePrefix + '_users', @users
		@organizationEventConnection = ResourceEventConnection.create @connection, 
			@exchange, 'organizations', queueNamePrefix + '_organizations', @organizations
		@buildEventConnection = ResourceEventConnection.create @connection, 
			@exchange, 'builds', queueNamePrefix + '_builds', @builds
		@buildOutputEventConnection = ResourceEventConnection.create @connection, 
			@exchange, 'buildOutputs', queueNamePrefix + '_buildOutputs', @buildOutputs
		@repositoryEventConnection = ResourceEventConnection.create @connection, 
			@exchange, 'repositories', queueNamePrefix + '_repositories', @repositories

		await
			@userEventConnection.connect defer userEventConnectionError
			@organizationEventConnection.connect defer organizationEventConnectionError
			@buildEventConnection.connect defer buildEventConnectionError
			@buildOutputEventConnection.connect defer buildOutputEventConnectionError
			@repositoryEventConnection.connect defer repositoryEventConnectionError

		connectionErrors = [userEventConnectionError, organizationEventConnectionError, 
			buildEventConnectionError, buildOutputEventConnectionError, repositoryEventConnectionError]
		errors = (error for error in connectionErrors when error?)

		if errors.length is 0 
			callback()
		else 
			callback errors
