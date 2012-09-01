profiler = require('nodetime').profile
	accountKey: 'e32c83cafbf931d5e47aca4c66f34bc7b36701f3'
	appName: 'Less Than Three'

os = require 'os'
cluster = require 'cluster'

configuration = require('./configuration')('./config.json')
environment = require('./environment')(configuration.mode)

ModelConnection = require './modelConnection'
Server = require './server/server'
RedirectServer = require './server/redirectServer'


startEverything = () ->
	modelConnection = ModelConnection.create configuration.server

	if configuration.server.cluster
		createMultipleServers configuration.server, modelConnection
	else
		createServers configuration.server, modelConnection


createMultipleServers = (serverConfigurationParams) ->
	if cluster.isMaster
		numCpus = os.cpus().length
		cluster.fork() for num in [0...numCpus]
	else
		createServers serverConfigurationParams, modelConnection


createServers = (serverConfigurationParams, modelConnection) ->
	redirectServer = RedirectServer.create configurationParams
	redirectServer.start()

	server = Server.createServer serverConfigurationParams, modelConnection
	server.start()


startEverything()
