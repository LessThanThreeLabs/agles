fs = require 'fs'
assert = require 'assert'
url = require 'url'
https = require 'https'
express = require 'express'

SessionStore = require './sessionStore'
CreateAccountStore = require './createAccountStore'
Configurer = require './configuration'
ResourceSocket = require './resourceSocket/resourceSocket'


exports.create = (configurationParams, modelConnection, resourceSocket) ->
	stores =
		sessionStore: SessionStore.create configurationParams
		createAccountStore: CreateAccountStore.create configurationParams
	
	configurer = Configurer.create configurationParams, stores.sessionStore
	resourceSocket ?= ResourceSocket.create configurationParams, stores, modelConnection

	return new Server configurer, modelConnection, resourceSocket, stores


class Server
	constructor: (@configurer, @modelConnection, @resourceSocket, @stores) ->
		assert.ok @configurer? and @modelConnection? and @resourceSocket? and @stores?


	start: () ->
		expressServer = express()
		@configurer.configure expressServer

		expressServer.get '/', @_handleIndexRequest
		expressServer.get '/verifyAccount', @_handleVerifyAccountRequest

		server = https.createServer @_getHttpsOptions(), expressServer
		server.listen @configurer.getConfigurationParams().https.port

		@resourceSocket.start server


	_handleIndexRequest: (request, response) =>
		response.render 'index', csrfToken: request.session.csrfToken


	_handleVerifyAccountRequest: (request, response) =>
		parsedUrl = url.parse request.url, true
		accountKey = parsedUrl.query.account
		
		@stores.createAccountStore.getAccount accountKey, (error, account) ->
			if error?
				response.send 'Invalid link' 
			else
				# push new account to the model server
				response.send "You have successfully loged in as #{account.firstName} #{account.lastName}!"


	_getHttpsOptions: () ->
		options = 
			key: fs.readFileSync @configurer.getConfigurationParams().security.key
			cert: fs.readFileSync @configurer.getConfigurationParams().security.certificate
			ca: fs.readFileSync @configurer.getConfigurationParams().security.certrequest
