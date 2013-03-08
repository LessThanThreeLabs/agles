assert = require 'assert'


module.exports = class Resource
	constructor: (@configurationParams, @stores, @modelRpcConnection, @filesCacher, @fileSuffix) ->
		assert.ok @configurationParams? 
		assert.ok @stores?
		assert.ok @modelRpcConnection?
		assert.ok @filesCacher?
		assert.ok @fileSuffix?


	initialize: (callback) =>
		@filesCacher.loadFiles (error) =>
			if error
				callback error
			else
				@loadResourceStrings()
				callback()


	handleRequest: (request, response) =>
		response.send 'response handler not written yet'


	getFiles: () =>
		assert.ok @filesCacher.getFiles()
		return @filesCacher.getFiles()


	loadResourceStrings: () =>
		@_createCssString()
		@_createJsString()


	_createCssString: () =>
		cssFileNames = Object.keys @getFiles().css
		formatedCssFiles = cssFileNames.map (cssFileName) =>
			return "<link rel='stylesheet' type='text/css' href='#{cssFileName}' />"
		@cssFilesString = formatedCssFiles.join '\n'


	_createJsString: () =>
		jsFileNames = Object.keys @getFiles().js
		formattedJsFiles = jsFileNames.map (jsFileName) =>
			return "<script src='#{jsFileName}'></script>"
		@jsFilesString = formattedJsFiles.join '\n'


	getTemplateValues: (session, callback) =>
		if session.userId?
			@modelRpcConnection.users.read.get_user_from_id session.userId, (error, user) =>
				if error? then callback error
				else callback null, @_generateTemplateValues session, user
		else
			callback null, @_generateTemplateValues session, null


	_generateTemplateValues: (session, user={}) =>
		fileSuffix: @fileSuffix
		csrfToken: session.csrfToken
		cssFiles: @cssFilesString
		jsFiles: @jsFilesString
		userId: session.userId
		email: user.email
		firstName: user.first_name
		lastName: user.last_name
		isAdmin: user.admin	? false
