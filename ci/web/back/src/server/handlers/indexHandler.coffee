fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelRpcConnection, filesSuffix) ->
	filesCacher = FilesCacher.create 'index', configurationParams, './cache/index.json', filesSuffix
	return new IndexHandler configurationParams, stores, modelRpcConnection, filesCacher, filesSuffix


class IndexHandler extends RequestHandler
	handleRequest: (request, response) =>
		@getTemplateValues request.session, (error, templateValues) =>
			if error?
				request.session.destroy()
				response.end 'internal server error'
			else 
				response.render 'index', templateValues
