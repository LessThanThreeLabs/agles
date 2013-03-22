fs = require 'fs'
colors = require 'colors'
assert = require 'assert'
express = require 'express'

Mailgun = require('mailgun').Mailgun


startServer = () ->
	emailer = new Mailgun 'key-9e06ajco0xurqnioji-egwuwajg4jrn2'

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

	expressServer.post '/reachOut', (request, response) ->
		fromEmail = 'Reach Out <reach-out@koalitycode.com>'
		toEmail = 'jpotter@koalitycode.com'
		subject = 'Reach Out'
		body = 'blah blah'
		
		emailer.sendText fromEmail, toEmail, subject, body, (error) ->
			if error? then response.end 'bad'
			else response.end 'ok'

	expressServer.listen 9000

	console.log 'Server started'.bold.magenta



startServer()