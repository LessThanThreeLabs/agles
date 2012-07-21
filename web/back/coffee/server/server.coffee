fs = require 'fs'
https = require 'https'
express = require 'express'
spdy = require 'spdy'


exports.start = (context) ->
	server = createBaseServer context
	startSpdyServer context, server


createBaseServer = (context) ->
	server = express.createServer()
	server.get '*', (request, response) ->
		# TODO: serve other files here through spdy
		response.sendfile './front/index.html'
	return server


startSpdyServer = (context, server) ->
	httpsPort = context.config.server.https.port
	spdyServer = spdy.createServer https.Server, getSpdyOptions(context), server
	spdyServer.listen httpsPort


getSpdyOptions = (context) ->
	options = 
		key: fs.readFileSync(process.cwd() + '/' + context.config.server.security.key)
		cert: fs.readFileSync(process.cwd() + '/' + context.config.server.security.certificate)
		ca: fs.readFileSync(process.cwd() + '/' + context.config.server.security.certrequest)