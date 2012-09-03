fs = require 'fs'
assert = require 'assert'
express = require 'express'

Configurer = require './configuration'
ResourceSocket = require './resourceSocket/resourceSocket'


exports.create = (configurationParams, modelConnection, resourceSocket) ->
	configurer = Configurer.create configurationParams
	resourceSocket ?= ResourceSocket.create configurationParams, modelConnection

	return new Server configurer, modelConnection, resourceSocket


class Server
	constructor: (@configurer, @modelConnection, @resourceSocket) ->
		assert.ok @configurer? and @modelConnection? and @resourceSocket?


	start: () ->
		@server = express.createServer @_getHttpsOptions()
		@configurer.configure @server

		@server.use '/', (request, response) ->
			response.render 'index', csrfToken: request.session._csrf

		@server.listen @configurer.getConfigurationParams().https.port

		@resourceSocket.start @server

		@_printThatServerStarted()


	_getHttpsOptions: () ->
		options = 
			key: fs.readFileSync @configurer.getConfigurationParams().security.key
			cert: fs.readFileSync @configurer.getConfigurationParams().security.certificate
			ca: fs.readFileSync @configurer.getConfigurationParams().security.certrequest


	_printThatServerStarted: () ->
		console.log 'Server started on port ' + @configurer.getConfigurationParams().https.port
