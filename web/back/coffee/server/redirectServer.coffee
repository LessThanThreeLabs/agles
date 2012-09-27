assert = require 'assert'
express = require 'express'


exports.create = (configurationParams) ->
	return new RedirectServer configurationParams


class RedirectServer
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	start: () ->
		@redirectServer = express()
		@redirectServer.get '*', (request, response) =>
			response.redirect 'https://' + request.headers.host + ':' + @configurationParams.https.port + request.url
		@redirectServer.listen @configurationParams.http.port 
