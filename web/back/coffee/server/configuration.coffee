fs = require 'fs'
assert = require 'assert'
fileWalker = require 'walk'
express = require 'express'
redisStore = require('connect-redis')(express)


exports.configureServer = (context, server) ->
	server.configure () ->
		server.use express.cookieParser()
		configureSessionLogic context, server
		server.use express.bodyParser()  # need this?
		server.use express.query()  # need this?
		configureCsrfLogic context, server
		server.use express.compress()	

	server.configure 'development', () ->
	    server.use express.errorHandler 
	    	dumpExceptions: true,
	    	showStack: true


configureCsrfLogic = (context, server) ->
	staticDirectories = context.config.server.staticFiles.staticDirectories

	server.use (request, response, next) ->
		if (staticDirectories.some (staticDirectory) ->
				return request.url.indexOf(staticDirectory + '/') == 0)
			next()
		else
			express.csrf()(request, response, next)


configureSessionLogic = (context, server) ->
	server.use express.session
    	secret: context.config.server.session.secret
    	cookie:
    		path: '/',
    		httpOnly: true,
    		secure: true,
    		maxAge: 14400000
    	store: new redisStore
    		port: context.config.server.redis.port

	ignoreStaticFilesFromSessionLogic context


ignoreStaticFilesFromSessionLogic = (context) ->
	express.session.ignore.push '/favicon.ico'

	rootDirectory = context.config.server.staticFiles.rootDirectory
	staticDirectories = context.config.server.staticFiles.staticDirectories

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
