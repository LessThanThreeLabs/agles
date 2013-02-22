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


	pushFiles: (request, response) =>
		if not request.isSpdy
			console.log 'spdy not supported!'
			return

		for files in [@getFiles().js, @getFiles().css, @getFiles().html]
			for fileName, file of files
				@_pushFile request, response, fileName, file


	_pushFile: (request, response, fileName, file) =>
		useGzip = request.gzipAllowed and file.gzip?

		headers = 
			'content-type': file.contentType
			'content-length': if useGzip then file.gzip.length else file.plain.length
			'cache-control': 'max-age=2592000'
		headers['content-encoding'] = 'gzip' if useGzip

		response.push fileName, headers, (error, stream) =>
			if error?
				console.error error
			else
				data = if useGzip then file.gzip else file.plain
				assert.ok data?
				stream.end data, 'binary'
				