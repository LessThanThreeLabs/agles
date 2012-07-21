context = require './context'
environment = require './environment'
server = require './server/main'

environment.setup context
server.start context