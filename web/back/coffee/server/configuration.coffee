fs = require 'fs'
assert = require 'assert'
fileWalker = require 'walk'
express = require 'express'
redisStore = require('connect-redis')(express)


exports.configureServer = (server, serverConfiguration) ->
	server.configure () ->
		server.use express.cookieParser()
		configureSessionLogic server, serverConfiguration
		server.use express.bodyParser()  # need this?
		server.use express.query()  # need this?
		configureCsrfLogic server, serverConfiguration
		server.use express.compress()
		configureViewEngine server, serverConfiguration

	server.configure 'development', () ->
	    server.use express.errorHandler 
	    	dumpExceptions: true,
	    	showStack: true


configureViewEngine = (server, serverConfiguration) ->
	rootStaticDirectory = serverConfiguration.staticFiles.rootDirectory

	server.set 'view engine', 'hbs'
	server.set 'view options', layout: false
	server.set 'views', serverConfiguration.staticFiles.rootDirectory


configureCsrfLogic = (server, serverConfiguration) ->
	staticDirectories = serverConfiguration.staticFiles.staticDirectories
	shouldIgnoreCsrfLogic = (url) ->
		return url == '/favicon.ico' ||
			staticDirectories.some (staticDirectory) ->
				return url.indexOf(staticDirectory + '/') == 0

	server.use (request, response, next) ->
		if shouldIgnoreCsrfLogic request.url
			next()
		else
			express.csrf()(request, response, next)


configureSessionLogic = (server, serverConfiguration) ->
	server.use express.session
    	secret: serverConfiguration.session.secret
    	cookie:
    		path: '/',
    		httpOnly: true,
    		secure: true,
    		maxAge: 14400000
    	store: new redisStore
    		port: serverConfiguration.redis.port

	ignoreStaticFilesFromSessionLogic serverConfiguration


ignoreStaticFilesFromSessionLogic = (serverConfiguration) ->
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
