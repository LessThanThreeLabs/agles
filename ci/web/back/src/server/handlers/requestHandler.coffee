assert = require 'assert'


module.exports = class Resource
	constructor: (@configurationParams, @stores, @modelRpcConnection, @filesCacher, @fileSuffix, @logger) ->
		assert.ok @configurationParams? 
		assert.ok @stores?
		assert.ok @modelRpcConnection?
		assert.ok @filesCacher?
		assert.ok @fileSuffix?
		assert.ok @logger?


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
		cssFiles = @getFiles().css
		if not cssFiles?
			@cssFilesString = ''
		else
			cssFileNames = Object.keys cssFiles
			formatedCssFiles = cssFileNames.map (cssFileName) =>
				return "<link rel='stylesheet' type='text/css' href='#{cssFileName}' />"
			@cssFilesString = formatedCssFiles.join '\n'


	_createJsString: () =>
		jsFiles = @getFiles().js
		if not jsFiles?
			@jsFilesString = ''
		else
			jsFileNames = Object.keys jsFiles
			formattedJsFiles = jsFileNames.map (jsFileName) =>
				return "<script src='#{jsFileName}'></script>"
			@jsFilesString = formattedJsFiles.join '\n'
