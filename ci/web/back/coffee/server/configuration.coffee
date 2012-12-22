fs = require 'fs'
assert = require 'assert'
express = require 'express'
csrf = require './csrf'


exports.create = (configurationParams, sessionStore) ->
	return new ServerConfigurer configurationParams, sessionStore


class ServerConfigurer
	constructor: (@configurationParams, @sessionStore) ->
		assert.ok @configurationParams? and @sessionStore?


	configure: (server) ->
		server.configure () =>
			# ORDER HERE IS VERY IMPORTANT!!!!
			server.use express.cookieParser()
			# server.use express.bodyParser()  # need this?
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
