fs = require 'fs'
assert = require 'assert'
fileWalker = require 'walk'
express = require 'express'
redisStore = require('connect-redis')(express)


exports.create = (configurationParams) ->
	return new ServerConfigurer configurationParams


class ServerConfigurer
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	getConfigurationParams: () ->
		return @configurationParams


	configure: (server) ->
		server.configure () =>
			server.use express.cookieParser()
			server.use express.bodyParser()  # need this?
			server.use express.query()  # need this?
			server.use express.compress()
			@_configureSessionLogic server
			@_configureViewEngine server
			@_configureStaticServer server

		server.configure 'development', () ->
		    server.use express.errorHandler 
		    	dumpExceptions: true,
		    	showStack: true


	_configureViewEngine: (server) ->
		server.set 'view engine', 'hbs'
		server.set 'view options', layout: false
		server.set 'views', @configurationParams.staticFiles.rootDirectory


	_configureStaticServer: (server) ->
		server.use express.favicon @configurationParams.staticFiles.rootDirectory + '/favicon.ico'

		server.use express.staticCache
			maxObjects: @configurationParams.staticFiles.cache.maxObjects
			maxLength: @configurationParams.staticFiles.cache.maxLength

		for staticDirectory in @configurationParams.staticFiles.staticDirectories
			server.use staticDirectory,
				express.static @configurationParams.staticFiles.rootDirectory + staticDirectory


	_configureSessionLogic: (server) ->
		server.use express.session
	    	secret: @configurationParams.session.secret
	    	cookie:
	    		path: '/',
	    		httpOnly: true,
	    		secure: true,
	    		maxAge: 14400000
	    	store: new redisStore
	    		url: @configurationParams.redis.url
	    		port: @configurationParams.redis.port

		@_ignoreStaticFilesFromSessionLogic()


	_ignoreStaticFilesFromSessionLogic: () ->
		console.log '_ignoreStaticBlah has sideeffects!!!! '

		express.session.ignore.push '/favicon.ico'

		rootDirectory = @configurationParams.staticFiles.rootDirectory
		staticDirectories = @configurationParams.staticFiles.staticDirectories

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
