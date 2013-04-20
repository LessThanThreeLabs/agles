fs = require 'fs'
assert = require 'assert'
https = require 'https'
express = require 'express'
csrf = require './csrf'
gzip = require './gzip'

ResourceConnection = require 'koality-resource-connection'
StaticServer = require './static/staticServer'

SessionStore = require './stores/sessionStore'
CreateAccountStore = require './stores/createAccountStore'
CreateRepositoryStore = require './stores/createRepositoryStore'

IndexHandler = require './handlers/indexHandler'
InstallationWizardHandler = require './handlers/installationWizardHandler'
UnexpectedErrorHandler = require './handlers/unexpectedErrorHandler'
InvalidPermissionsHandler = require './handlers/invalidPermissionsHandler'


exports.create = (configurationParams, modelConnection, mailer, logger) ->
	stores =
		sessionStore: SessionStore.create configurationParams
		createAccountStore: CreateAccountStore.create configurationParams
		createRepositoryStore: CreateRepositoryStore.create configurationParams
	
	cookieName = configurationParams.session.cookie.name
	transports = configurationParams.socket.transports
	resourceConnection = ResourceConnection.create configurationParams.resources, modelConnection, stores, cookieName, transports, mailer, logger
	staticServer = StaticServer.create configurationParams

	httpsOptions =
		key: fs.readFileSync configurationParams.https.security.key
		cert: fs.readFileSync configurationParams.https.security.certificate
		ca: fs.readFileSync configurationParams.https.security.certrequest

	filesSuffix = '_' + (new Date()).getTime().toString 36
	handlers =
		indexHandler: IndexHandler.create configurationParams, stores, modelConnection.rpcConnection, filesSuffix, logger
		installationWizardHandler: InstallationWizardHandler.create configurationParams, stores, modelConnection.rpcConnection, filesSuffix, logger
		unexpectedErrorHandler: UnexpectedErrorHandler.create configurationParams, stores, modelConnection.rpcConnection, filesSuffix, logger
		invalidPermissionsHandler: InvalidPermissionsHandler.create configurationParams, stores, modelConnection.rpcConnection, filesSuffix, logger

	return new Server configurationParams, httpsOptions, modelConnection, resourceConnection, stores, handlers, staticServer, logger


class Server
	constructor: (@configurationParams, @httpsOptions, @modelConnection, @resourceConnection, @stores, @handlers, @staticServer, @logger) ->
		assert.ok @configurationParams? and @httpsOptions? and @modelConnection? and
			@resourceConnection? and @stores? and @handlers? and @staticServer? and @logger?


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
			@handlers.indexHandler.initialize defer errors.indexHandlerError
			@handlers.installationWizardHandler.initialize defer errors.insallationWizardHandlerError
			@handlers.unexpectedErrorHandler.initialize defer errors.unexpectedErrorHandlerError
			@handlers.invalidPermissionsHandler.initialize defer errors.invalidPermissionsHandlerError

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


	start: () =>
		addInstallationWizardBindings = () =>
			expressServer.get '/', @handlers.installationWizardHandler.handleRequest
			expressServer.get '/wizard', @handlers.installationWizardHandler.handleRequest
			expressServer.post '/turnOffInstallationWizard', turnOffInstallationWizard
			expressServer.get '*', @staticServer.handleRequest

		turnOffInstallationWizard = (request, response) =>
			removeInstallationWizardBindings()
			addProjectBindings()
			response.end 'ok'

		removeInstallationWizardBindings = () =>
			expressServer.routes.get = expressServer.routes.get.filter (route) ->
				route.path isnt '/'
			expressServer.routes.get = expressServer.routes.get.filter (route) ->
				route.path isnt '/wizard'
			expressServer.routes.post = expressServer.routes.post.filter (route) ->
				route.path isnt '/turnOffInstallationWizard'
			expressServer.routes.get = expressServer.routes.get.filter (route) ->
				route.path isnt '*'

		addProjectBindings = () =>
			expressServer.get '/', @handlers.indexHandler.handleRequest
			expressServer.get '/welcome', @handlers.indexHandler.handleRequest
			expressServer.get '/login', @handlers.indexHandler.handleRequest
			expressServer.get '/account', @handlers.indexHandler.handleRequest
			expressServer.get '/create/account', @handlers.indexHandler.handleRequest
			expressServer.get '/resetPassword', @handlers.indexHandler.handleRequest
			expressServer.get '/repository/:repositoryId', @handlers.indexHandler.handleRequest
			expressServer.get '/admin', @handlers.indexHandler.handleRequest
			expressServer.get '/unexpectedError', @handlers.unexpectedErrorHandler.handleRequest
			expressServer.get '/invalidPermissions', @handlers.invalidPermissionsHandler.handleRequest
			expressServer.post '/extendCookieExpiration', @_handleExtendCookieExpiration
			expressServer.get '*', @staticServer.handleRequest

		expressServer = express()
		@_configure expressServer

		@modelConnection.rpcConnection.systemSettings.read.is_deployment_initialized (error, initialized) =>
			if error? @logger.error error
			else
				if initialized then addProjectBindings()
				else addInstallationWizardBindings()

				server = https.createServer @httpsOptions, expressServer
				server.listen @configurationParams.https.port

				@resourceConnection.start server

				@logger.info 'server started'
				console.log "SERVER STARTED on port #{@configurationParams.https.port}".bold.magenta


	_configure: (expressServer) =>
		# ORDER IS IMPORTANT HERE!!!!
		expressServer.use express.favicon 'front/favicon.ico'
		expressServer.use express.cookieParser()
		expressServer.use express.query()
		expressServer.use express.session
	    	secret: @configurationParams.session.secret
	    	key: @configurationParams.session.cookie.name
	    	cookie:
	    		path: '/'
	    		httpOnly: true
	    		secure: true
	    	store: @stores.sessionStore
		expressServer.use csrf()
		expressServer.use gzip()

		expressServer.set 'view engine', 'ejs'
		expressServer.set 'views', @configurationParams.staticFiles.rootDirectory
		expressServer.locals.layout = false


	_handleExtendCookieExpiration: (request, response) =>
		if not request.session.userId?
			response.end '403'
		else
			request.session.cookie.maxAge = @configurationParams.session.rememberMeDuration
			request.session.cookieExpirationIncreased ?= 0 
			request.session.cookieExpirationIncreased++
			response.end 'ok'
