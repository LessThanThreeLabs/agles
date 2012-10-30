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

		console.log request.headers['accept-encoding']
		# send every file over the stream, possibly already compressed

		@_pushFilesOfType request, response, 'css', 'text/css'
		@_pushFilesOfType request, response, 'js', 'application/javascript'


	_pushFilesOfType: (request, response, fileType, contentType) =>
		files = @filesCacher.getFiles fileType
		for file in files
			@_pushFile request, response, file, 'content-type': contentType


	_pushFile: (request, response, file, headers) =>
		response.push '/' + file.name, headers, (error, stream) =>
			if error?
				console.error error
				return
			stream.end file.plainText
