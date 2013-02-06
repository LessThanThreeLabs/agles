assert = require 'assert'

ResourceEventConnection = require './resourceEventConnection'

UserEventHandler = require './handlers/userEventHandler'
ChangeEventHandler = require './handlers/changeEventHandler'
BuildConsoleEventHandler = require './handlers/buildOutputEventHandler'
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
		@changes = ChangeEventHandler.create @sockets
		@buildConsoles = BuildConsoleEventHandler.create @sockets
		@repositories = RepositoryEventHandler.create @sockets

		@_connectHandlers callback


	_connectHandlers: (callback) =>
		queueNamePrefix = @configurationParams.events.queueNamePrefix

		@userEventConnection = ResourceEventConnection.create @connection, 
			@exchange, 'users', queueNamePrefix + '_users', @users
		@changeEventConnection = ResourceEventConnection.create @connection,
			@exchange, 'changes', queueNamePrefix + '_changes', @changes
		@buildConsoleEventConnection = ResourceEventConnection.create @connection, 
			@exchange, 'build_consoles', queueNamePrefix + '_buildConsoles', @buildConsoles
		@repositoryEventConnection = ResourceEventConnection.create @connection, 
			@exchange, 'repos', queueNamePrefix + '_repositories', @repositories

		await
			@userEventConnection.connect defer userEventConnectionError
			@changeEventConnection.connect defer changeEventConnectionError
			@buildConsoleEventConnection.connect defer buildConsoleEventConnectionError
			@repositoryEventConnection.connect defer repositoryEventConnectionError

		connectionErrors = [userEventConnectionError, changeEventConnectionError,
			buildConsoleEventConnectionError, repositoryEventConnectionError]
		errors = (error for error in connectionErrors when error?)

		if errors.length is 0 
			callback()
		else 
			callback errors
