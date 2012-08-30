fs = require 'fs'
express = require 'express'
resource = require 'express-resource'
redirectServer = require './redirectServer'
configurer = require './configuration'
socket = require './socket/socket'


exports.start = (serverConfiguration, modelConnection) ->
	server = startServer serverConfiguration
	redirectServer.start serverConfiguration
	socket.start server, serverConfiguration

	console.log 'Server started.'


startServer = (serverConfiguration) ->
	server = express.createServer getHttpsOptions serverConfiguration
	configurer.configureServer server, serverConfiguration

	setupStaticServer server, serverConfiguration

	server.use '/', (request, response) ->
		response.render 'index', csrfToken: request.session._csrf
	
	httpsPort = serverConfiguration.https.port
	server.listen httpsPort

	return server


setupStaticServer = (server, serverConfiguration) ->
	rootStaticDirectory = serverConfiguration.staticFiles.rootDirectory
	server.use express.favicon(rootStaticDirectory + '/favicon.ico')

	staticCacheParams = serverConfiguration.staticFiles.cache
	server.use express.staticCache
		maxObjects: staticCacheParams.maxObjects
		maxLength: staticCacheParams.maxLength

	rootStaticDirectory = serverConfiguration.staticFiles.rootDirectory
	staticDirectories = serverConfiguration.staticFiles.staticDirectories
	for staticDirectory in staticDirectories
		server.use staticDirectory, express.static rootStaticDirectory + staticDirectory


getHttpsOptions = (serverConfiguration) ->
	options = 
		key: fs.readFileSync serverConfiguration.security.key
		cert: fs.readFileSync serverConfiguration.security.certificate
		ca: fs.readFileSync serverConfiguration.security.certrequest
