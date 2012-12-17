fs = require 'fs'
assert = require 'assert'
spdy = require 'spdy'
express = require 'express'

SessionStore = require './sessionStore'
CreateAccountStore = require './createAccountStore'
Configurer = require './configuration'
ResourceSocket = require './resourceSocket/resourceSocket'
SpdyCache = require './spdyCache/spdyCache'

WelcomeHandler = require './handlers/welcomeHandler'
CreateAccountHandler = require './handlers/createAccountHandler'
VerifyAccountHandler = require './handlers/verifyAccountHandler'
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
		verifyAccountHandler: VerifyAccountHandler.create configurationParams, stores, modelConnection
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
			@handlers.verifyAccountHandler.initialize defer verifyAccountHandlerError
			@handlers.recoverPasswordHandler.initialize defer recoverPasswordHandlerError

		errors = (error for error in [welcomeHandlerError, createAccountHandlerError, 
			verifyAccountHandlerError, recoverPasswordHandlerError] when error?)
		if errors.length > 0
			callback errors.join ' '
		else
			callback()


	start: () ->
		expressServer = express()
		@configurer.configure expressServer

		expressServer.get '/', @handlers.welcomeHandler.handleRequest
		expressServer.get '/createAccount', @handlers.createAccountHandler.handleRequest
		expressServer.get '/verifyAccount', @handlers.verifyAccountHandler.handleRequest
		expressServer.get '/recoverPassword', @handlers.recoverPasswordHandler.handleRequest
		
		# should server static content from here too
		# (in memory)

		server = spdy.createServer @httpsOptions, expressServer
		server.listen @port

		@resourceSocket.start server
