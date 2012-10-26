fs = require 'fs'
assert = require 'assert'
express = require 'express'
csrf = require './csrf'


exports.create = (configurationParams, sessionStore) ->
	return new ServerConfigurer configurationParams, sessionStore


class ServerConfigurer
	constructor: (@configurationParams, @sessionStore) ->
		assert.ok @configurationParams? and @sessionStore?


	getConfigurationParams: () ->
		return @configurationParams


	configure: (server) ->
		server.configure () =>
			# ORDER HERE IS VERY IMPORTANT!!!!
			server.use express.compress()
			@_configureStaticServer server
			server.use express.cookieParser()
			server.use express.bodyParser()  # need this?
			server.use express.query()  # need this?
			@_configureSessionLogic server
			server.use csrf()
			@_configureViewEngine server

		server.configure 'development', () ->
			server.use express.errorHandler 
				dumpExceptions: true,
				showStack: true


	_configureViewEngine: (server) ->
		server.set 'view engine', 'hbs'
		server.set 'views', @configurationParams.staticFiles.rootDirectory
		server.locals.layout = false


	_configureStaticServer: (server) ->
		server.use express.favicon @configurationParams.staticFiles.rootDirectory + '/favicon.ico'

		for staticDirectory in @configurationParams.staticFiles.staticDirectories
			server.use staticDirectory,
				express.static @configurationParams.staticFiles.rootDirectory + staticDirectory, maxAge: 0
				# TODO: determine correct maxage!!!!


	_configureSessionLogic: (server) ->
		server.use express.session
	    	secret: @configurationParams.session.secret
	    	key: @configurationParams.session.cookie.name
	    	cookie:
	    		path: '/',
	    		httpOnly: true,
	    		secure: true,
	    		maxAge: 14400000
	    	store: @sessionStore
