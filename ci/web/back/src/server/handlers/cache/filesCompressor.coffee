zlib = require 'zlib'
assert = require 'assert'


exports.create = (configurationParams) ->
	return new FilesCompressor configurationParams


class FilesCompressor
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	addCompressedFiles: (files, callback) =>
		await
			for fileType of files
				for fileName, file of files[fileType]
					continue if not @_shouldGzip file.contentType
					zlib.gzip file.plain, defer file.gzipError, file.gzip

		combinedErrors = ''
		for fileType of files
			for fileName, file of files[fileType]
				combinedErrors += file.gzipError + ' ' if file.gzipError?

		if combinedErrors isnt ''
			callback combinedErrors
		else
			callback null, files


	_shouldGzip: (contentType) =>
		switch contentType
			when 'text/html', 'text/css', 'application/javascript', 'image/svg+xml'
				return true
			when 'image/png', 'image/jpeg', 'application/x-font-woff'
				return false
			else
				throw new Error 'Unaccounted for content type'
