express = require 'express'

exports.start = (serverConfiguration) ->
	httpPort = serverConfiguration.http.port 
	httpsPort = serverConfiguration.https.port

	redirectServer = express.createServer()
	redirectServer.get '*', (request, response) ->
		response.redirect 'https://' + request.headers.host + ':' + httpsPort + request.url
	redirectServer.listen httpPort