fs = require 'fs'
assert = require 'assert'
fileWalker = require 'walk'
express = require 'express'
redisStore = require('connect-redis')(express)


exports.create = (configurationParams) ->
	return new ServerConfigurer configurationParams


class ServerConfigurer
	constructor: (@configurationParams) ->


	getConfigurationParams: () ->
		return @configurationParams


	configure: (server) ->
		server.configure () ->
			server.use express.cookieParser()
			configureSessionLogic server
			server.use express.bodyParser()  # need this?
			server.use express.query()  # need this?
			configureCsrfLogic server
			server.use express.compress()
			_configureViewEngine server

		server.configure 'development', () ->
		    server.use express.errorHandler 
		    	dumpExceptions: true,
		    	showStack: true


	_configureViewEngine: (server) ->
		server.set 'view engine', 'hbs'
		server.set 'view options', layout: false
		server.set 'views', @configurationParams.staticFiles.rootDirectory


	_configureStaticServer: (server) ->
		server.use express.favicon @configuration.staticFiles.rootDirectory + '/favicon.ico'

		server.use express.staticCache
			maxObjects: @configuration.staticFiles.cache.maxObjects
			maxLength: @configuration.staticFiles.cache.maxLength

		for staticDirectory in @configuration.staticFiles.staticDirectories
			@server.use staticDirectory,
				express.static @configuration.staticFiles.rootDirectory + staticDirectory


	_configureSessionLogic: (server) ->
		server.use express.session
	    	secret: @configurationParams.session.secret
	    	cookie:
	    		path: '/',
	    		httpOnly: true,
	    		secure: true,
	    		maxAge: 14400000
	    	store: new redisStore
	    		port: @configurationParams.redis.port

		_ignoreStaticFilesFromSessionLogic()


	_ignoreStaticFilesFromSessionLogic: () ->
		console.log '_ignoreStaticBlah has sideeffects!!!! '

		express.session.ignore.push '/favicon.ico'

		rootDirectory = serverConfiguration.staticFiles.rootDirectory
		staticDirectories = serverConfiguration.staticFiles.staticDirectories

		for staticDirectory in staticDirectories
			directory = rootDirectory + staticDirectory

			walker = fileWalker.walkSync directory, followLinks: true

			walker.on 'file', (root, fileStats, next) ->
				fileToIgnore = root + '/' + fileStats.name
				staticFileToIgnore = fileToIgnore.substring fileToIgnore.indexOf staticDirectory
				express.session.ignore.push staticFileToIgnore
				next()

			walker.on 'end', () ->
				assert.ok express.session.ignore.length > 1,
					'Problem finding static files to ignore from session logic.'
