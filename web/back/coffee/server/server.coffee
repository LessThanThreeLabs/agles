fs = require 'fs'
fileWalker = require 'walk'
express = require 'express'
redisStore = require('connect-redis')(express)


exports.start = (context) ->
	server = express.createServer getHttpsOptions context
	configureServer context, server

	server.get '/', (request, response) ->
		response.sendfile './front/index.html'
	
	httpsPort = context.config.server.https.port
	server.listen httpsPort


configureServer = (context, server) ->
	server.configure () ->
		# TODO: decide what middleware we need as we go
	    # server.use express.methodOverride()
	    # server.use express.bodyParser()

	    server.use express.cookieParser()

	    server.use express.session
	    	secret: context.config.server.session.secret
	    	cookie: 
	    		path: '/',
	    		httpOnly: true,
	    		secure: true,
	    		maxAge: 14400000
	    	store: new redisStore
	    		port: context.config.server.redis.port

		express.session.ignore.push '/favicon.ico'
		ignoreStaticFilesFromSessionLogic context

		server.use '/img', express.static process.cwd() + '/front/img'

	server.configure 'development', () ->
	    server.use express.errorHandler 
	    	dumpExceptions: true, 
	    	showStack: true


ignoreStaticFilesFromSessionLogic = (context) ->
	rootDirectory = process.cwd() + '/' + context.config.server.staticFiles.rootDirectory

	for serverDirectory in context.config.server.staticFiles.directoriesToIgnoreFromSessionLogic
		directory = rootDirectory + serverDirectory

		walker = fileWalker.walkSync directory, followLinks: true
		walker.on 'file', (root, fileStats, next) ->
			fileToIgnore = root + '/' + fileStats.name
			serverFileToIgnore = fileToIgnore.substring fileToIgnore.indexOf serverDirectory
			express.session.ignore.push serverFileToIgnore
			next()


getHttpsOptions = (context) ->
	options = 
		key: fs.readFileSync process.cwd() + '/' + context.config.server.security.key
		cert: fs.readFileSync process.cwd() + '/' + context.config.server.security.certificate
		ca: fs.readFileSync process.cwd() + '/' + context.config.server.security.certrequest
