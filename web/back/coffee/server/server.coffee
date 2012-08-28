fs = require 'fs'
express = require 'express'
resource = require 'express-resource'
redirectServer = require './redirectServer'
configurer = require './configuration'
socket = require './socket/socket'


exports.start = (context) ->
	server = startServer context
	redirectServer.start context
	socket.start context, server

	console.log 'Server started.'


startServer = (context) ->
	server = express.createServer getHttpsOptions context
	configurer.configureServer context, server

	setupStaticServer context, server

	server.use '/', (request, response) ->
		response.render 'index', csrfToken: request.session._csrf
	
	httpsPort = context.config.server.https.port
	server.listen httpsPort

	return server


setupStaticServer = (context, server) ->
	rootStaticDirectory = context.config.server.staticFiles.rootDirectory
	server.use express.favicon(rootStaticDirectory + '/favicon.ico')

	staticCacheParams = context.config.server.staticFiles.cache
	server.use express.staticCache
		maxObjects: staticCacheParams.maxObjects
		maxLength: staticCacheParams.maxLength

	rootStaticDirectory = context.config.server.staticFiles.rootDirectory
	staticDirectories = context.config.server.staticFiles.staticDirectories
	for staticDirectory in staticDirectories
		server.use staticDirectory, express.static rootStaticDirectory + staticDirectory


getHttpsOptions = (context) ->
	options = 
		key: fs.readFileSync context.config.server.security.key
		cert: fs.readFileSync context.config.server.security.certificate
		ca: fs.readFileSync context.config.server.security.certrequest
