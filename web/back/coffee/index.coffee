profiler = require('nodetime').profile
	accountKey: 'e32c83cafbf931d5e47aca4c66f34bc7b36701f3'
	appName: 'Agles'

context = require './context'
environment = require './environment'
server = require './server/main'

environment.setup context
server.start context