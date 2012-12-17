fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelConnection) ->
	filesCacher = FilesCacher.create configurationParams, './cache/recoverPassword.json'
	return new RecoverPasswordHandler configurationParams, stores, modelConnection, filesCacher


class RecoverPasswordHandler extends RequestHandler
	constructor: (configurationParams, stores, modelConnection, filesCacher) ->
		super configurationParams, stores, modelConnection, filesCacher


	handleRequest: (request, response) =>
		@pushFiles request, response
		response.render 'index', @getTemplateValues request
