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
			url = @_getUrlFromHost request.headers.host
			response.redirect 'https://' + url + ':' + @configurationParams.https.port + request.url
		@redirectServer.listen @configurationParams.http.port 

		console.log @configurationParams.http.port 


	_getUrlFromHost: (host) =>
		colonIndex = host.indexOf ':'
		return host.substr 0, if colonIndex is -1 then host.length else colonIndex
