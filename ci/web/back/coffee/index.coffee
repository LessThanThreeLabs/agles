os = require 'os'
cluster = require 'cluster'
profiler = require 'nodetime'
configuration = require('./configuration')
environment = require('./environment')


startEverything = () ->
	configurationParams = configuration.getConfigurationParams './config.json'
	environment.setEnvironmentMode configurationParams.mode
	startProfiler configurationParams.profiler

	createServers configurationParams.server


startProfiler = (profilerConfigurationParams) ->
	profiler.profile
		appName: profilerConfigurationParams.applicationName
		accountKey: profilerConfigurationParams.accountKey
		silent: profilerConfigurationParams.silent


createServers = (serverConfigurationParams) ->
	numWorkers = if serverConfigurationParams.cluster then os.cpus().length else 1

	cluster.setupMaster exec: "js/worker"
	cluster.fork() for num in [0...numWorkers]
	
	console.log numWorkers + ' servers started on port ' + serverConfigurationParams.http.port + ' (http)' +
		' and port ' + serverConfigurationParams.https.port + ' (https)'


startEverything()
