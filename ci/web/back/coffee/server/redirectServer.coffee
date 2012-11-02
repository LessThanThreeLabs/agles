assert = require 'assert'
express = require 'express'


exports.create = (port) ->
	return new RedirectServer port


class RedirectServer
	constructor: (@port) ->
		assert.ok @port?


	start: () ->
		@redirectServer = express()
		@redirectServer.get '*', (request, response) =>
			response.redirect 'https://' + request.headers.host + request.url
		@redirectServer.listen @port
