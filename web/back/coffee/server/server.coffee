fs = require 'fs'
express = require 'express'


exports.start = (context) ->
	server = express.createServer getHttpsOptions(context)

	server.get '*', (request, response) ->
		response.sendfile './front/index.html'
	
	httpsPort = context.config.server.https.port
	server.listen httpsPort


getHttpsOptions = (context) ->
	options = 
		key: fs.readFileSync(process.cwd() + '/' + context.config.server.security.key)
		cert: fs.readFileSync(process.cwd() + '/' + context.config.server.security.certificate)
		ca: fs.readFileSync(process.cwd() + '/' + context.config.server.security.certrequest)