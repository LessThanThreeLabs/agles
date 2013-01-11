fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelConnection, filesSuffix) ->
	filesCacher = FilesCacher.create configurationParams, './cache/recoverPassword.json', filesSuffix
	return new RecoverPasswordHandler configurationParams, stores, modelConnection, filesCacher, filesSuffix


class RecoverPasswordHandler extends RequestHandler
	constructor: (configurationParams, stores, modelConnection, filesCacher, filesSuffix) ->
		super configurationParams, stores, modelConnection, filesCacher, filesSuffix


	handleRequest: (request, response) =>
		if request.session.userId?
			response.redirect 302, '/'
		else
			@pushFiles request, response
			response.render 'index', @getTemplateValues request
