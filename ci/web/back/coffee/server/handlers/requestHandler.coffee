assert = require 'assert'


module.exports = class Resource
	constructor: (@configurationParams, @stores, @modelConnection, @filesCacher) ->
		assert.ok @configurationParams? and @stores? and @modelConnection? and @filesCacher?


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


	getTemplateValues: (request) =>
		templateValues =
			csrfToken: request.session.csrfToken
			cssFiles: @cssFilesString
			jsFiles: @jsFilesString
			email: request.session.email
			firstName: request.session.firstName
			lastName: request.session.lastName

		return templateValues


	pushFiles: (request, response) =>
		if not request.isSpdy
			console.log 'spdy not supported!'
			return

		useGzip = @_canUseGzip request.headers

		for fileType, files of @getFiles()
			for fileName, file of files
				@_pushFile request, response, fileName, file, useGzip


	_pushFile: (request, response, fileName, file, useGzip) =>
		useGzip = false if not file.gzip?

		headers = 'content-type': file.contentType
		headers['content-encoding'] = 'gzip' if useGzip

		response.push fileName, headers, (error, stream) =>
			if error?
				console.error error
			else
				data = if useGzip then file.gzip else file.plain
				assert.ok data?
				stream.end data, 'binary'
				

	_canUseGzip: (headers) =>
		return false if not headers['accept-encoding']?
		return true if headers['accept-encoding'].trim() is '*'

		encodings = headers['accept-encoding'].split ','
		return encodings.some (encoding) =>
			return encoding is 'gzip'
			