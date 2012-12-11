zlib = require 'zlib'
assert = require 'assert'


exports.create = (configurationParams) ->
	return new FilesCompressor configurationParams


class FilesCompressor
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	addCompressedFiles: (files, callback) =>
		console.log 'Compressing files...'
		
		gzipErrors = {}

		await
			for fileType of files
				gzipErrors[fileType] = []
				for file, index in files[fileType]
					continue if not @_shouldGzip file.contentType
					zlib.gzip file.plain, defer gzipErrors[fileType][index], files[fileType][index].gzip

		if @_containsAnyErrors gzipErrors
			callback 'Unable to gzip all the files'
		else
			callback()


	_shouldGzip: (contentType) =>
		switch contentType
			when 'text/css', 'application/javascript', 'image/svg+xml'
				return true
			when 'image/png', 'application/x-font-woff'
				return false
			else
				throw new Error 'Unaccounted for content type'


	_containsAnyErrors: (gzipErrors) =>
		for fileType in Object.keys gzipErrors
			anyErrors = gzipErrors[fileType].some (fileError) =>
				return fileError?
			return true if anyErrors

		return false
