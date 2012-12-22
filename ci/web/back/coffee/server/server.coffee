fs = require 'fs'
assert = require 'assert'
spdy = require 'spdy'
express = require 'express'

SessionStore = require './sessionStore'
CreateAccountStore = require './createAccountStore'
Configurer = require './configuration'
ResourceSocket = require './resourceSocket/resourceSocket'
StaticServer = require './static/staticServer'

WelcomeHandler = require './handlers/welcomeHandler'
AccountHandler = require './handlers/accountHandler'
CreateAccountHandler = require './handlers/createAccountHandler'
VerifyAccountHandler = require './handlers/verifyAccountHandler'
RecoverPasswordHandler = require './handlers/recoverPasswordHandler'
CreateRepositoryHandler = require './handlers/createRepositoryHandler'
RepositoryHandler = require './handlers/repositoryHandler'


exports.create = (configurationParams, modelConnection, port) ->
	stores =
		sessionStore: SessionStore.create configurationParams
		createAccountStore: CreateAccountStore.create configurationParams
	
	configurer = Configurer.create configurationParams, stores.sessionStore
	resourceSocket = ResourceSocket.create configurationParams, stores, modelConnection
	staticServer = StaticServer.create configurationParams

	httpsOptions =
		key: fs.readFileSync configurationParams.security.key
		cert: fs.readFileSync configurationParams.security.certificate
		ca: fs.readFileSync configurationParams.security.certrequest

	handlers =
		welcomeHandler: WelcomeHandler.create configurationParams, stores, modelConnection
		accountHandler: AccountHandler.create configurationParams, stores, modelConnection
		createAccountHandler: CreateAccountHandler.create configurationParams, stores, modelConnection
		verifyAccountHandler: VerifyAccountHandler.create configurationParams, stores, modelConnection
		recoverPasswordHandler: RecoverPasswordHandler.create configurationParams, stores, modelConnection
		createRepositoryHandler: CreateRepositoryHandler.create configurationParams, stores, modelConnection
		repositoryHandler: RepositoryHandler.create configurationParams, stores, modelConnection

	return new Server configurer, httpsOptions, port, modelConnection, resourceSocket, stores, handlers, staticServer


class Server
	constructor: (@configurer, @httpsOptions, @port, @modelConnection, @resourceSocket, @stores, @handlers, @staticServer) ->
		assert.ok @configurer? and @httpsOptions? and @port? and @modelConnection? and 
			@resourceSocket? and @stores? and @handlers? and @staticServer?


	initialize: (callback) =>
		@_initializeHandlers (error) =>
			if error?
				callback error
			else
				@_initializeStaticServer callback


	_initializeHandlers: (callback) =>
		# if this seciton is causing problems, be sure to increase
		# the maximum number of files you can have open
		errors = {}
		await
			@handlers.welcomeHandler.initialize defer errors.welcomeHandlerError
			@handlers.accountHandler.initialize defer errors.accountHandlerError
			@handlers.createAccountHandler.initialize defer errors.createAccountHandlerError
			@handlers.verifyAccountHandler.initialize defer errors.verifyAccountHandlerError
			@handlers.recoverPasswordHandler.initialize defer errors.recoverPasswordHandlerError
			@handlers.createRepositoryHandler.initialize defer errors.createRepositoryHandlerError
			@handlers.repositoryHandler.initialize defer errors.repositoryHandlerError

		combinedErrors = []
		for key, error of errors
			combinedErrors.push error if error?

		if combinedErrors.length > 0
			callback combinedErrors.join ' '
		else
			callback()


	_initializeStaticServer: (callback) =>
		for handlerName, handler of @handlers
			@staticServer.addFiles handler.getFiles()

		callback()


	start: () ->
		expressServer = express()
		@configurer.configure expressServer

		expressServer.get '/', @handlers.welcomeHandler.handleRequest
		expressServer.get '/account', @handlers.accountHandler.handleRequest
		expressServer.get '/account/create', @handlers.createAccountHandler.handleRequest
		expressServer.get '/account/:view', @handlers.accountHandler.handleRequest
		expressServer.get '/verifyAccount', @handlers.verifyAccountHandler.handleRequest
		expressServer.get '/recoverPassword', @handlers.recoverPasswordHandler.handleRequest
		expressServer.get '/repository/create', @handlers.createRepositoryHandler.handleRequest
		expressServer.get '/repository/:repositoryId', @handlers.repositoryHandler.handleRequest
		expressServer.get '/repository/:repositoryId/:repositoryView', @handlers.repositoryHandler.handleRequest
		expressServer.get '/repository/:repositoryId/:repositoryView/:changeId', @handlers.repositoryHandler.handleRequest
		expressServer.get '/repository/:repositoryId/:repositoryView/:changeId/:changeView', @handlers.repositoryHandler.handleRequest
		expressServer.get '*', @staticServer.handleRequest		

		server = spdy.createServer @httpsOptions, expressServer
		server.listen @port

		@resourceSocket.start server

		console.log 'SERVER STARTED'
