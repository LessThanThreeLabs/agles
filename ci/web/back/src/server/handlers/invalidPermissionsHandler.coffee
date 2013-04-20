fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelRpcConnection, filesSuffix, logger) ->
	filesCacher = FilesCacher.create 'invalid permissions', configurationParams, './cache/invalidPermissions.json', filesSuffix, logger
	return new InvalidPermissionsHandler configurationParams, stores, modelRpcConnection, filesCacher, filesSuffix, logger


class InvalidPermissionsHandler extends RequestHandler
	handleRequest: (request, response) =>
		response.end 'Invaild Permissions'
