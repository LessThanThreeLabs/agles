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
	server.use '/js', express.static rootStaticDirectory + '/js'
	server.use '/img', express.static rootStaticDirectory + '/img'


getHttpsOptions = (context) ->
	options = 
		key: fs.readFileSync context.config.server.security.key
		cert: fs.readFileSync context.config.server.security.certificate
		ca: fs.readFileSync context.config.server.security.certrequest
