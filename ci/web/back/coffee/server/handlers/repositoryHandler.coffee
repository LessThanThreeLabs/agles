fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelConnection, filesSuffix) ->
	filesCacher = FilesCacher.create configurationParams, './cache/repository.json', filesSuffix
	return new RepositoryHandler configurationParams, stores, modelConnection, filesCacher, filesSuffix


class RepositoryHandler extends RequestHandler
	constructor: (configurationParams, stores, modelConnection, filesCacher, filesSuffix) ->
		super configurationParams, stores, modelConnection, filesCacher, filesSuffix


	handleRequest: (request, response) =>
		@pushFiles request, response
		response.render 'index', @getTemplateValues request
