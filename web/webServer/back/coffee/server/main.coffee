server = require './server'
redirectServer = require './redirectServer'


exports.start = (context) ->
	server.start context
	redirectServer.start context
	printThatServersStarted context


printThatServersStarted = (context) ->
	httpPort = context.config.server.http.port
	httpsPort = context.config.server.https.port
	console.log 'Servers started on ' + httpPort + ' (http) and ' + httpsPort + ' (https)'