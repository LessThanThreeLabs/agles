express = require 'express'

exports.start = (context) ->
	httpPort = context.config.server.http.port 
	httpsPort = context.config.server.https.port

	redirectServer = express.createServer()
	redirectServer.get '*', (request, response) ->
		response.redirect 'https://' + request.headers.host + ':' + httpsPort + request.url
	redirectServer.listen httpPort