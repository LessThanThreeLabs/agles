fs = require 'fs'
express = require 'express'
resource = require 'express-resource'
serverConfigurer = require './configuration'


exports.start = (context) ->
	server = express.createServer getHttpsOptions context
	serverConfigurer.configureServer context, server

	addContextToRequestMiddleware context, server
	setupResources context, server
	setupStaticServer context, server
	
	httpsPort = context.config.server.https.port
	server.listen httpsPort


addContextToRequestMiddleware = (context, server) ->
	server.use (request, response, next) ->
		request.context = context
		next()


setupResources = (context, server) ->
	server.resource require('./resource/root')
	server.resource 'profile', require('./resource/profile'), format: 'json'


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
