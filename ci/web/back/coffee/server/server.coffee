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
		expressServer.get '/repository/:id', @_handleIndexRequest

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
		@spdyCache.pushFiles request, response
		response.render 'index', 
			csrfToken: request.session.csrfToken
			cssFiles: @cssFilesString
			jsFiles: @jsFilesString


	_handleVerifyAccountRequest: (request, response) =>
		parsedUrl = url.parse request.url, true
		accountKey = parsedUrl.query.account
		
		@stores.createAccountStore.getAccount accountKey, (error, account) =>
			if error?
				response.send 'Invalid link'
			else
				@stores.createAccountStore.removeAccount accountKey
				console.log 'need to push new account to the model server'
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
		