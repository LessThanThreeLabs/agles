fs = require 'fs'
zlib = require 'zlib'
assert = require 'assert'

FilesLoader = require './filesLoader'


exports.create = (configurationParams) ->
	filesLoader = FilesLoader.create configurationParams
	return new FilesCacher configurationParams, filesLoader


class FilesCacher
	files: null

	constructor: (@configurationParams, @filesLoader) ->
		assert.ok @configurationParams? and @filesLoader?


	loadFiles: (callback) =>
		@filesLoader.load (error, files) =>
			if error?
				callback error
			else
				@files = files
				@_addCompressedFiles callback


	_addCompressedFiles: (callback) =>
		gzipErrors = {}

		await
			for fileType of @files
				gzipErrors[fileType] = []
				for file, index in @files[fileType]
					continue if not @_shouldGzip file.contentType
					zlib.gzip file.plain, defer gzipErrors[fileType][index], @files[fileType][index].gzip

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


	getFileTypes: () =>
		assert.ok @files?
		return Object.keys @files


	getFiles: (fileType) =>
		assert.ok @files?
		return @files[fileType]
