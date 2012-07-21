server = require './server'
redirectServer = require './redirectServer'


exports.start = (context) ->
	server.start context
	redirectServer.start context
	printThatServersStarted context


printThatServersStarted = (context) ->
	httpPort = context.config.get 'server:http:port' 
	httpsPort = context.config.get 'server:https:port'
	console.log 'Servers started on ' + httpPort + ' (http) and ' + httpsPort + ' (https)'