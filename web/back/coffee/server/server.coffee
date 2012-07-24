fs = require 'fs'
express = require 'express'
serverConfigurer = require './configuration'


exports.start = (context) ->
	server = express.createServer getHttpsOptions context
	serverConfigurer.configureServer context, server

	setupStaticServer context, server
	server.get '/', (request, response) ->
		rootStaticDirectory = context.config.server.staticFiles.rootDirectory
		response.sendfile rootStaticDirectory + '/index.html'
	
	httpsPort = context.config.server.https.port
	server.listen httpsPort


setupStaticServer = (context, server) ->
	rootStaticDirectory = context.config.server.staticFiles.rootDirectory
	server.use '/img', express.static rootStaticDirectory + '/img'


getHttpsOptions = (context) ->
	options = 
		key: fs.readFileSync context.config.server.security.key
		cert: fs.readFileSync context.config.server.security.certificate
		ca: fs.readFileSync context.config.server.security.certrequest
