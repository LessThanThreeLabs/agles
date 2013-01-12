profiler = require 'nodetime'
configuration = require('./configuration')
environment = require('./environment')

CommandLineParser = require './commandLineParser'
ModelConnection = require './modelConnection/modelConnection'
Server = require './server/server'
RedirectServer = require './server/redirectServer'


startEverything = () ->
	process.title = 'webserver'

	commandLineParser = CommandLineParser.create()

	configurationParams = _getConfigurationFile commandLineParser.getConfigFile()
	httpPort = commandLineParser.getHttpPort() ? configurationParams.server.http.defaultPort
	httpsPort = commandLineParser.getHttpsPort() ? configurationParams.server.https.defaultPort

	environment.setEnvironmentMode configurationParams.mode

	modelConnection = ModelConnection.create configurationParams.modelConnection
	modelConnection.connect (error) =>
		throw error if error?
		createServers configurationParams.server, httpPort, httpsPort, modelConnection

	console.log 'need to pay for profiler...'
	# _startProfiler configurationParams.profiler

	if process.env.NODE_ENV is 'production'
		process.on 'uncaughtException', (error) =>
			console.error error


_getConfigurationFile = (configFile = './config.json') =>
	return configuration.getConfigurationParams configFile


_startProfiler = (profilerConfigurationParams) =>
	profiler.profile
		appName: profilerConfigurationParams.applicationName
		accountKey: profilerConfigurationParams.accountKey
		silent: profilerConfigurationParams.silent


createServers = (serverConfigurationParams, httpPort, httpsPort, modelConnection) =>
	redirectServer = RedirectServer.create httpPort
	redirectServer.start()

	server = Server.create serverConfigurationParams, modelConnection, httpsPort
	server.initialize (error) =>
		if error?
			console.error error
		else
			server.start()


startEverything()
