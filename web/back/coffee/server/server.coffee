fs = require 'fs'
assert = require 'assert'
https = require 'https'
express = require 'express'

SessionStore = require './sessionStore'
Configurer = require './configuration'
ResourceSocket = require './resourceSocket/resourceSocket'


exports.create = (configurationParams, modelConnection, resourceSocket) ->
	sessionStore = SessionStore.create configurationParams
	configurer = Configurer.create configurationParams, sessionStore
	resourceSocket ?= ResourceSocket.create configurationParams, sessionStore, modelConnection

	return new Server configurer, modelConnection, resourceSocket, sessionStore


class Server
	constructor: (@configurer, @modelConnection, @resourceSocket, @sessionStore) ->
		assert.ok @configurer? and @modelConnection? and @resourceSocket? and @sessionStore?


	start: () ->
		expressServer = express()
		@configurer.configure expressServer

		expressServer.use '/', (request, response) =>
			response.render 'index', csrfToken: request.session.csrfToken

		server = https.createServer @_getHttpsOptions(), expressServer
		server.listen @configurer.getConfigurationParams().https.port

		@resourceSocket.start server


	_getHttpsOptions: () ->
		options = 
			key: fs.readFileSync @configurer.getConfigurationParams().security.key
			cert: fs.readFileSync @configurer.getConfigurationParams().security.certificate
			ca: fs.readFileSync @configurer.getConfigurationParams().security.certrequest
