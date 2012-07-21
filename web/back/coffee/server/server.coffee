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
		response.send 'sup nerd?'
	return server


startSpdyServer = (context, server) ->
	httpsPort = context.config.get 'server:https:port'
	spdyServer = spdy.createServer https.Server, getSpdyOptions(context), server
	spdyServer.listen httpsPort


getSpdyOptions = (context) ->
	options = 
		key: fs.readFileSync(process.cwd() + '/' + context.config.get 'server:security:key')
		cert: fs.readFileSync(process.cwd() + '/' + context.config.get 'server:security:certificate')
		ca: fs.readFileSync(process.cwd() + '/' + context.config.get 'server:security:certrequest')