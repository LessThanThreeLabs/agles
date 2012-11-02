assert = require 'assert'
express = require 'express'


exports.create = (port) ->
	return new RedirectServer port


class RedirectServer
	constructor: (@port) ->
		assert.ok @port?


	start: () =>
		@redirectServer = express()
		@redirectServer.get '*', (request, response) =>
			response.redirect 'https://' + @_getHostWithoutPort(request.headers.host) + request.url
		@redirectServer.listen @port


	_getHostWithoutPort: (host) =>
		colonIndex = host.indexOf ':'
		if colonIndex isnt -1
			return host.substr 0, colonIndex
		else
			return host
