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


exports.create = (configurationParams, modelConnection) ->
	stores =
		sessionStore: SessionStore.create configurationParams
		createAccountStore: CreateAccountStore.create configurationParams
	
	configurer = Configurer.create configurationParams, stores.sessionStore
	resourceSocket = ResourceSocket.create configurationParams, stores, modelConnection
	spdyCache = SpdyCache.create configurationParams

	return new Server configurer, modelConnection, resourceSocket, spdyCache, stores


class Server
	constructor: (@configurer, @modelConnection, @resourceSocket, @spdyCache, @stores) ->
		assert.ok @configurer? and @modelConnection? and @resourceSocket? and @spdyCache? and @stores?


	start: () ->
		expressServer = express()
		@configurer.configure expressServer

		expressServer.get '/', @_handleIndexRequest
		expressServer.get '/verifyAccount', @_handleVerifyAccountRequest

		server = spdy.createServer @_getHttpsOptions(), expressServer
		server.listen @configurer.getConfigurationParams().https.port

		@resourceSocket.start server

		@spdyCache.load (error) =>
			throw error if error?
			console.log '...server ready'


	_handleIndexRequest: (request, response) =>
		@spdyCache.pushFiles request, response
		console.log 'shouldnt we save index.hbs locally?'
		
		cssFiles = @_getCssString @spdyCache.getFileNames 'css'
		jsFiles = @_getJsStrings @spdyCache.getFileNames 'js'
		response.render 'index', 
			csrfToken: request.session.csrfToken
			cssFiles: cssFiles.join('\n')
			jsFiles: jsFiles.join('\n')


	_getCssString: (cssFileNames) =>
		return cssFileNames.map (cssFileName) =>
			return "<link rel='stylesheet' type='text/css' href='#{cssFileName}' />"


	_getJsStrings: (jsFileNames) =>
		return jsFileNames.map (jsFileName) =>
			return "<script src='#{jsFileName}'></script>"


	_handleVerifyAccountRequest: (request, response) =>
		parsedUrl = url.parse request.url, true
		accountKey = parsedUrl.query.account
		
		@stores.createAccountStore.getAccount accountKey, (error, account) =>
			if error?
				response.send 'Invalid link'
			else
				@stores.createAccountStore.removeAccount accountKey
				# push new account to the model server
				response.render 'verifyAccount',
					firstName: account.firstName
					lastName: account.lastName


	_getHttpsOptions: () ->
		options = 
			key: fs.readFileSync @configurer.getConfigurationParams().security.key
			cert: fs.readFileSync @configurer.getConfigurationParams().security.certificate
			ca: fs.readFileSync @configurer.getConfigurationParams().security.certrequest
