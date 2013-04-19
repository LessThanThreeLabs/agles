fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelRpcConnection, filesSuffix, logger) ->
	filesCacher = FilesCacher.create 'installation wizard', configurationParams, './cache/installationWizard.json', filesSuffix, logger
	return new InstallationWizardHandler configurationParams, stores, modelRpcConnection, filesCacher, filesSuffix, logger


class InstallationWizardHandler extends RequestHandler
	handleRequest: (request, response) =>
		# just in case there's a lingering session
		delete request.session.userId

		response.render 'installationWizard', 
			fileSuffix: @fileSuffix
			csrfToken: request.session.csrfToken
			cssFiles: @cssFilesString
			jsFiles: @jsFilesString
			