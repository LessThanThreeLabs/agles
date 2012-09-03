configuration = require('./configuration')
environment = require('./environment')

ModelConnection = require './modelConnection/modelConnection'
Server = require './server/server'
RedirectServer = require './server/redirectServer'


startWorker = () ->
	configurationParams = configuration.getConfigurationParams './config.json'
	environment.setEnvironmentMode configurationParams.mode

	modelConnection = ModelConnection.create configurationParams
	createServers configurationParams.server, modelConnection


createServers = (serverConfigurationParams, modelConnection) ->
	redirectServer = RedirectServer.create serverConfigurationParams
	redirectServer.start()

	server = Server.create serverConfigurationParams, modelConnection
	server.start()


startWorker()
