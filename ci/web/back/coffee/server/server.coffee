fs = require 'fs'
assert = require 'assert'
url = require 'url'
spdy = require 'spdy'
express = require 'express'

SessionStore = require './sessionStore'
CreateAccountStore = require './createAccountStore'
Configurer = require './configuration'
ResourceSocket = require './resourceSocket/resourceSocket'
SpdyCache = require './spdyCache/spdyCache'

WelcomeHandler = require './handlers/welcomeHandler'
CreateAccountHandler = require './handlers/createAccountHandler'
RecoverPasswordHandler = require './handlers/recoverPasswordHandler'


exports.create = (configurationParams, modelConnection, port) ->
	stores =
		sessionStore: SessionStore.create configurationParams
		createAccountStore: CreateAccountStore.create configurationParams
	
	configurer = Configurer.create configurationParams, stores.sessionStore
	resourceSocket = ResourceSocket.create configurationParams, stores, modelConnection

	httpsOptions =
		key: fs.readFileSync configurationParams.security.key
		cert: fs.readFileSync configurationParams.security.certificate
		ca: fs.readFileSync configurationParams.security.certrequest

	handlers =
		welcomeHandler: WelcomeHandler.create configurationParams, stores, modelConnection
		createAccountHandler: CreateAccountHandler.create configurationParams, stores, modelConnection
		recoverPasswordHandler: RecoverPasswordHandler.create configurationParams, stores, modelConnection

	return new Server configurer, httpsOptions, port, modelConnection, resourceSocket, stores, handlers


class Server
	constructor: (@configurer, @httpsOptions, @port, @modelConnection, @resourceSocket, @stores, @handlers) ->
		assert.ok @configurer? and @httpsOptions? and @port? and @modelConnection? and 
			@resourceSocket? and @stores? and @handlers?


	initialize: (callback) =>
		await
			@handlers.welcomeHandler.initialize defer welcomeHandlerError
			@handlers.createAccountHandler.initialize defer createAccountHandlerError
			@handlers.recoverPasswordHandler.initialize defer recoverPasswordHandlerError

		errors = (error for error in [welcomeHandlerError, createAccountHandlerError, recoverPasswordHandlerError] when error?)
		if errors.length > 0
			callback errors.join ' '
		else
			callback()


	start: () ->
		expressServer = express()
		@configurer.configure expressServer

		expressServer.get '/', @handlers.welcomeHandler.handleRequest
		expressServer.get '/createAccount', @handlers.createAccountHandler.handleRequest
		expressServer.get '/recoverPassword', @handlers.recoverPasswordHandler.handleRequest
		
		# should server static content from here too
		# (in memory)

		server = spdy.createServer @httpsOptions, expressServer
		server.listen @port

		@resourceSocket.start server


	_handleVerifyAccountRequest: (request, response) =>
		parsedUrl = url.parse request.url, true
		accountKey = parsedUrl.query.account
		
		@stores.createAccountStore.getAccount accountKey, (error, account) =>
			if error?
				response.end 'Invalid link'
			else
				@stores.createAccountStore.removeAccount accountKey

				userToCreate =
					email: account.email
					salt: account.salt
					password_hash: account.passwordHash
					first_name: account.firstName
					last_name: account.lastName

				@modelConnection.rpcConnection.users.create.create_user userToCreate, (error, userId) =>
					if error?
						response.end 'User creation failed'
					else
						request.session.userId = userId

						response.render 'verifyAccount',
							firstName: account.firstName
							lastName: account.lastName


	_createCssString: () =>
		cssFileNames = @spdyCache.getFileNames 'css'
		formatedCssFiles = cssFileNames.map (cssFileName) =>
			return "<link rel='stylesheet' type='text/css' href='#{cssFileName}' />"
		@cssFilesString = formatedCssFiles.join '\n'


	_createJsString: () =>
		jsFileNames = @spdyCache.getFileNames 'js'
		formattedJsFiles = jsFileNames.map (jsFileName) =>
			return "<script src='#{jsFileName}'></script>"
		@jsFilesString = formattedJsFiles.join '\n'
		