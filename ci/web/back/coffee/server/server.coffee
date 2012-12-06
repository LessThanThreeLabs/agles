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


exports.create = (configurationParams, modelConnection, port) ->
	stores =
		sessionStore: SessionStore.create configurationParams
		createAccountStore: CreateAccountStore.create configurationParams
	
	configurer = Configurer.create configurationParams, stores.sessionStore
	resourceSocket = ResourceSocket.create configurationParams, stores, modelConnection
	spdyCache = SpdyCache.create configurationParams

	httpsOptions =
		key: fs.readFileSync configurationParams.security.key
		cert: fs.readFileSync configurationParams.security.certificate
		ca: fs.readFileSync configurationParams.security.certrequest

	return new Server configurer, httpsOptions, port, modelConnection, resourceSocket, spdyCache, stores


class Server
	constructor: (@configurer, @httpsOptions, @port, @modelConnection, @resourceSocket, @spdyCache, @stores) ->
		assert.ok @configurer? and @httpsOptions? and @port? and @modelConnection? and @resourceSocket? and @spdyCache? and @stores?


	start: () ->
		expressServer = express()
		@configurer.configure expressServer

		expressServer.get '/', @_handleIndexRequest
		expressServer.get '/account', @_handleIndexRequest
		expressServer.get '/repository/:repositoryId', @_handleIndexRequest
		expressServer.get '/repository/:repositoryId/:repositoryView', @_handleIndexRequest
		expressServer.get '/repository/:repositoryId/builds/:buildId', @_handleIndexRequest
		expressServer.get '/repository/:repositoryId/builds/:buildId/:buildView', @_handleIndexRequest
		expressServer.get '/create/repository', @_handleIndexRequest

		expressServer.get '/verifyAccount', @_handleVerifyAccountRequest

		# should server static content from here too
		# (in memory)

		server = spdy.createServer @httpsOptions, expressServer
		server.listen @port

		@resourceSocket.start server

		@spdyCache.load (error) =>
			throw error if error?

			@_createCssString()
			@_createJsString()

			console.log 'Server running!'


	_handleIndexRequest: (request, response) =>
		if @_isAllowedToVisitRoute request
			@spdyCache.pushFiles request, response
			response.render 'index', 
				csrfToken: request.session.csrfToken
				cssFiles: @cssFilesString
				jsFiles: @jsFilesString
		else
			response.send 'Some nice 404 page here'


	_isAllowedToVisitRoute: (request) =>
		console.log 'server.coffee -- logic needs to be more comprehensive here...'
		console.log '  might also want to remove this if we can better handle invalid states in client'
		return request.url is '/' or request.session.userId?


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
						response.end 'User Creation Failed'
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
		