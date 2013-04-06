fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelRpcConnection, filesSuffix) ->
	filesCacher = FilesCacher.create 'index', configurationParams, './cache/installationWizard.json', filesSuffix
	return new InstallationWizardHandler configurationParams, stores, modelRpcConnection, filesCacher, filesSuffix


class InstallationWizardHandler extends RequestHandler
	handleRequest: (request, response) =>
		# just in case there's a lingering session
		request.session.userId = null

		response.render 'installationWizard', 
			fileSuffix: @fileSuffix
			csrfToken: request.session.csrfToken
			cssFiles: @cssFilesString
			jsFiles: @jsFilesString
			