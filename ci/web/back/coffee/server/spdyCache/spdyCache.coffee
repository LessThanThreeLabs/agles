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
		@_pushFilesOfType request, response, 'css', 'text/css', useGzip
		@_pushFilesOfType request, response, 'js', 'application/javascript', useGzip


	_canUseGzip: (headers) =>
		return false if not headers['accept-encoding']?
		return true if headers['accept-encoding'].trim() is '*'

		encodings = headers['accept-encoding'].split ','
		return encodings.some (encoding) =>
			return encoding is 'gzip'


	_pushFilesOfType: (request, response, fileType, contentType, useGzip) =>
		files = @filesCacher.getFiles fileType
		for file in files
			headers = 'content-type': contentType
			headers['content-encoding'] = 'gzip' if useGzip
			@_pushFile request, response, file, headers, useGzip


	_pushFile: (request, response, file, headers, useGzip) =>
		response.push '/' + file.name, headers, (error, stream) =>
			if error?
				console.error error
				return
			stream.end if useGzip then file.gzip else file.plainText
