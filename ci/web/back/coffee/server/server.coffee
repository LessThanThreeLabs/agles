fs = require 'fs'
assert = require 'assert'
spdy = require 'spdy'
express = require 'express'
csrf = require './csrf'
gzip = require './gzip'

ResourceSocket = require './resourceSocket/resourceSocket'
StaticServer = require './static/staticServer'

SessionStore = require './stores/sessionStore'
CreateAccountStore = require './stores/createAccountStore'

IndexHandler = require './handlers/indexHandler'
# WelcomeHandler = require './handlers/welcomeHandler'
# AccountHandler = require './handlers/accountHandler'
# CreateAccountHandler = require './handlers/createAccountHandler'
# VerifyAccountHandler = require './handlers/verifyAccountHandler'
# RecoverPasswordHandler = require './handlers/recoverPasswordHandler'
# CreateRepositoryHandler = require './handlers/createRepositoryHandler'
# RepositoryHandler = require './handlers/repositoryHandler'


exports.create = (configurationParams, modelConnection, port) ->
	stores =
		sessionStore: SessionStore.create configurationParams
		createAccountStore: CreateAccountStore.create configurationParams
	
	resourceSocket = ResourceSocket.create configurationParams, stores, modelConnection
	staticServer = StaticServer.create configurationParams

	httpsOptions =
		key: fs.readFileSync configurationParams.security.key
		cert: fs.readFileSync configurationParams.security.certificate
		ca: fs.readFileSync configurationParams.security.certrequest

	filesSuffix = '_' + (new Date()).getTime().toString 36
	handlers =
		indexHandler: IndexHandler.create configurationParams, stores, modelConnection, filesSuffix
		# welcomeHandler: WelcomeHandler.create configurationParams, stores, modelConnection, filesSuffix
		# accountHandler: AccountHandler.create configurationParams, stores, modelConnection, filesSuffix
		# createAccountHandler: CreateAccountHandler.create configurationParams, stores, modelConnection, filesSuffix
		# verifyAccountHandler: VerifyAccountHandler.create configurationParams, stores, modelConnection, filesSuffix
		# recoverPasswordHandler: RecoverPasswordHandler.create configurationParams, stores, modelConnection, filesSuffix
		# createRepositoryHandler: CreateRepositoryHandler.create configurationParams, stores, modelConnection, filesSuffix
		# repositoryHandler: RepositoryHandler.create configurationParams, stores, modelConnection, filesSuffix

	return new Server configurationParams, httpsOptions, port, modelConnection, resourceSocket, stores, handlers, staticServer


class Server
	constructor: (@configurationParams, @httpsOptions, @port, @modelConnection, @resourceSocket, @stores, @handlers, @staticServer) ->
		assert.ok @configurationParams? and @httpsOptions? and @port? and @modelConnection? and 
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
			@handlers.indexHandler.initialize defer errors.indexHandlerError
			# @handlers.welcomeHandler.initialize defer errors.welcomeHandlerError
			# @handlers.accountHandler.initialize defer errors.accountHandlerError
			# @handlers.createAccountHandler.initialize defer errors.createAccountHandlerError
			# @handlers.verifyAccountHandler.initialize defer errors.verifyAccountHandlerError
			# @handlers.recoverPasswordHandler.initialize defer errors.recoverPasswordHandlerError
			# @handlers.createRepositoryHandler.initialize defer errors.createRepositoryHandlerError
			# @handlers.repositoryHandler.initialize defer errors.repositoryHandlerError

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
		expressServer = express()
		@_configureServer expressServer

		expressServer.get '/', @handlers.indexHandler.handleRequest
		expressServer.get '/welcome', @handlers.indexHandler.handleRequest
		expressServer.get '/login', @handlers.indexHandler.handleRequest
		expressServer.get '/create/account', @handlers.indexHandler.handleRequest
		expressServer.get '/recoverPassword', @handlers.indexHandler.handleRequest

		# expressServer.get '/', @handlers.welcomeHandler.handleRequest
		# expressServer.get '/account', @handlers.accountHandler.handleRequest
		# expressServer.get '/account/create', @handlers.createAccountHandler.handleRequest
		# expressServer.get '/account/:view', @handlers.accountHandler.handleRequest
		# expressServer.get '/verifyAccount', @handlers.verifyAccountHandler.handleRequest
		# expressServer.get '/recoverPassword', @handlers.recoverPasswordHandler.handleRequest
		# expressServer.get '/repository/create', @handlers.createRepositoryHandler.handleRequest
		# expressServer.get '/repository/:repositoryId', @handlers.repositoryHandler.handleRequest
		# expressServer.get '/repository/:repositoryId/:repositoryView', @handlers.repositoryHandler.handleRequest
		# expressServer.get '/repository/:repositoryId/:repositoryView/:changeId', @handlers.repositoryHandler.handleRequest
		# expressServer.get '/repository/:repositoryId/:repositoryView/:changeId/:changeView', @handlers.repositoryHandler.handleRequest
		expressServer.get '*', @staticServer.handleRequest		

		expressServer.post '/fixCookieExpiration', @_handleFixCookieExpiration

		server = spdy.createServer @httpsOptions, expressServer
		server.listen @port

		@resourceSocket.start server

		console.log "SERVER STARTED on port #{@port}".bold.magenta


	_configureServer: (expressServer) =>
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


	_handleFixCookieExpiration: (request, response) =>
		if not request.session.userId?
			response.end '403'
		else
			request.session.cookie.maxAge = @configurationParams.session.rememberMeDuration
			request.session.cookieExpirationIncreased ?= 0 
			request.session.cookieExpirationIncreased++
			response.end 'ok'
