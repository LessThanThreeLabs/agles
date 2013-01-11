fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelConnection, filesSuffix) ->
	filesCacher = FilesCacher.create configurationParams, './cache/createRepository.json', filesSuffix
	return new CreateRepositoryHandler configurationParams, stores, modelConnection, filesCacher, filesSuffix


class CreateRepositoryHandler extends RequestHandler
	constructor: (configurationParams, stores, modelConnection, filesCacher, filesSuffix) ->
		super configurationParams, stores, modelConnection, filesCacher, filesSuffix


	handleRequest: (request, response) =>
		if not request.session.userId?
			response.redirect 302, '/'
		else
			@pushFiles request, response
			response.render 'index', @getTemplateValues request
