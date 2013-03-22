fs = require 'fs'
colors = require 'colors'
assert = require 'assert'
express = require 'express'


startServer = () ->
	expressServer = express()

	expressServer.use express.favicon 'front/favicon.ico'
	expressServer.use express.bodyParser()
	expressServer.use express.compress()

	expressServer.use '/js', express.static 'front/js'
	expressServer.use '/css', express.static 'front/css'
	expressServer.use '/img', express.static 'front/img', maxAge: 86400000
	expressServer.use '/font', express.static 'front/font', maxAge: 86400000

	expressServer.get '/', (request, response) ->
		response.sendfile 'front/index.html'
	expressServer.post '/reachOut', reachOut
	expressServer.listen 9000

	console.log 'Server started'.bold.magenta


reachOut = (request, response) ->
	response.end 'cool'


startServer()