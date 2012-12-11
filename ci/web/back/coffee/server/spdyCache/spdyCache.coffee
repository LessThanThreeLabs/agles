fs = require 'fs'
assert = require 'assert'

FilesCacher = require './filesCacher'


exports.create = (configurationParams) ->
	filesCacher = FilesCacher.create configurationParams
	return new SpdyCache configurationParams, filesCacher


class SpdyCache
	constructor: (@configurationParams, @filesCacher) ->
		assert.ok @configurationParams? and @filesCacher?


	load: (callback) =>
		@filesCacher.loadFiles callback


	pushFiles: (request, response) =>
		if not request.isSpdy
			console.log 'spdy not supported!'
			return

		useGzip = @_canUseGzip request.headers
		for fileType in @filesCacher.getFileTypes()
			@_pushFilesOfType request, response, fileType, useGzip


	_canUseGzip: (headers) =>
		return false if not headers['accept-encoding']?
		return true if headers['accept-encoding'].trim() is '*'

		encodings = headers['accept-encoding'].split ','
		return encodings.some (encoding) =>
			return encoding is 'gzip'


	_pushFilesOfType: (request, response, fileType, useGzip) =>
		files = @filesCacher.getFiles fileType
		for file in files
			@_pushFile request, response, file, useGzip


	_pushFile: (request, response, file, useGzip) =>
		useGzip = false if not file.gzip?

		headers = 'content-type': file.contentType
		headers['content-encoding'] = 'gzip' if useGzip

		response.push file.name, headers, (error, stream) =>
			if error?
				console.error error
			else
				data = if useGzip then file.gzip else file.plain
				assert.ok data?
				stream.end data, 'binary'


	getFileNames: (fileType) =>
		files = @filesCacher.getFiles fileType

		return files.map (file) =>
			return file.name
