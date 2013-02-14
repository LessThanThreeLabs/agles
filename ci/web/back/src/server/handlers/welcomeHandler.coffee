fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelConnection, filesSuffix) ->
	filesCacher = FilesCacher.create 'welcome', configurationParams, './cache/welcome.json', filesSuffix
	return new WelcomeHandler configurationParams, stores, modelConnection, filesCacher, filesSuffix


class WelcomeHandler extends RequestHandler
	constructor: (configurationParams, stores, modelConnection, filesCacher, filesSuffix) ->
		super configurationParams, stores, modelConnection, filesCacher, filesSuffix


	handleRequest: (request, response) =>
		@pushFiles request, response
		response.render 'index', @getTemplateValues request
