express = require 'express'

exports.start = (context) ->
	httpPort = context.config.get 'server:http:port' 
	httpsPort = context.config.get 'server:https:port'

	redirectServer = express.createServer()
	redirectServer.get '*', (request, response) ->
		response.redirect 'https://' + request.headers.host + ':' + httpsPort + request.url
	redirectServer.listen httpPort