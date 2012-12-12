fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelConnection) ->
	filesCacher = FilesCacher.create configurationParams, './cache/welcome.json'
	return new WelcomeHandler configurationParams, stores, modelConnection, filesCacher


class WelcomeHandler extends RequestHandler
	constructor: (configurationParams, stores, modelConnection, filesCacher) ->
		super configurationParams, stores, modelConnection, filesCacher


	initialize: (callback) =>
		@filesCacher.loadFiles (error) =>
			if error
				callback error
			else
				@loadResourceStrings()
				callback()


	handleRequest: (request, response) =>
		@pushFiles request, response

		templateValues =
			csrfToken: request.session.csrfToken
			cssFiles: @cssFilesString
			jsFiles: @jsFilesString

		# if request.session.userId?
		# 	@modelConnection.rpcConnection.users.read.get_user_from_id request.session.userId, (error, user) =>
		# 		if error?
		# 			console.error "UserId #{request.session.userId} doesn't exist: " + error
		# 		else
		# 			templateValues.userEmail = user.email
		# 			templateValues.userFirstName = user.first_name
		# 			templateValues.userLastName = user.last_name

		# 		response.render 'index', templateValues
		# else
		response.render 'index', templateValues
