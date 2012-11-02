configuration = require('./configuration')
environment = require('./environment')

ModelConnection = require './modelConnection/modelConnection'
Server = require './server/server'
RedirectServer = require './server/redirectServer'


startWorker = () ->
	# process.on 'uncaughtException', (error) ->
	# 	console.error error
		
	configurationParams = configuration.getConfigurationParams './config.json'
	environment.setEnvironmentMode configurationParams.mode

	modelConnection = ModelConnection.create configurationParams.modelConnection
	modelConnection.connect (error) ->
		throw error if error?
		createServers configurationParams.server, modelConnection


createServers = (serverConfigurationParams, modelConnection) ->
	redirectServer = RedirectServer.create serverConfigurationParams.http.defaultPort
	redirectServer.start()

	server = Server.create serverConfigurationParams, modelConnection, serverConfigurationParams.https.defaultPort
	server.start()


startWorker()
