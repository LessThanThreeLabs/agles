fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelConnection) ->
	filesCacher = FilesCacher.create configurationParams, './cache/account.json'
	return new AccountHandler configurationParams, stores, modelConnection, filesCacher


class AccountHandler extends RequestHandler
	constructor: (configurationParams, stores, modelConnection, filesCacher) ->
		super configurationParams, stores, modelConnection, filesCacher


	handleRequest: (request, response) =>
		if not request.session.userId?
			response.redirect 302, '/'
		else
			@pushFiles request, response
			response.render 'index', @getTemplateValues request
