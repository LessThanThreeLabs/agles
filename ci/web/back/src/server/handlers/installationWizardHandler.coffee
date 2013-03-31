fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelRpcConnection, filesSuffix) ->
	filesCacher = FilesCacher.create 'index', configurationParams, './cache/installationWizard.json', filesSuffix
	return new InstallationWizardHandler configurationParams, stores, modelRpcConnection, filesCacher, filesSuffix


class InstallationWizardHandler extends RequestHandler
	handleRequest: (request, response) =>
		response.render 'installationWizard', 
			fileSuffix: @fileSuffix
			cssFiles: @cssFilesString
			jsFiles: @jsFilesString
			