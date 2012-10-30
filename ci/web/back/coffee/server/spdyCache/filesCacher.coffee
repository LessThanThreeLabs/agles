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
			for fileType in Object.keys @files
				gzipErrors[fileType] = []
				for file, index in @files[fileType]
					zlib.gzip file.plainText, defer gzipErrors[fileType][index], @files[fileType][index].gzip

		if @_containsAnyErrors gzipErrors
			callback 'Unable to gzip all the files'
		else
			callback()


	_containsAnyErrors: (gzipErrors) =>
		for fileType in Object.keys gzipErrors
			anyErrors = gzipErrors[fileType].some (fileError) =>
				return fileError?
			return true if anyErrors

		return false


	getFiles: (fileType) =>
		assert.ok @files?
		return @files[fileType]
