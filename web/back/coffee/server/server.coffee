fs = require 'fs'
express = require 'express'


exports.start = (context) ->
	server = express.createServer getHttpsOptions context
	configureServer context, server

	server.get '/', (request, response) ->
		response.sendfile './front/index.html'
	
	httpsPort = context.config.server.https.port
	server.listen httpsPort


configureServer = (context, server) ->
	server.configure () ->
		# TODO: decide which ones we need as we go
	    # server.use express.methodOverride()
	    # server.use express.bodyParser()
	    server.use '/img', express.static process.cwd() + '/front/img'

	server.configure 'development', () ->
	    server.use express.errorHandler 
	    	dumpExceptions: true, 
	    	showStack: true


getHttpsOptions = (context) ->
	options = 
		key: fs.readFileSync(process.cwd() + '/' + context.config.server.security.key)
		cert: fs.readFileSync(process.cwd() + '/' + context.config.server.security.certificate)
		ca: fs.readFileSync(process.cwd() + '/' + context.config.server.security.certrequest)