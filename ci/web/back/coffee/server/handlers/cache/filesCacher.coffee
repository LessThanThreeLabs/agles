assert = require 'assert'

FilesLoader = require './filesLoader'
FilesMinifier = require './filesMinifier'
FilesCompressor = require './filesCompressor'


exports.create = (configurationParams, filesToLoadUri) ->
	filesLoader = FilesLoader.create configurationParams, filesToLoadUri
	filesMinifier = FilesMinifier.create configurationParams
	filesCompressor = FilesCompressor.create configurationParams
	return new FilesCacher configurationParams, filesLoader, filesMinifier, filesCompressor


class FilesCacher
	_files: null

	constructor: (@configurationParams, @filesLoader, @filesMinifier, @filesCompressor) ->
		assert.ok @configurationParams? and @filesLoader? and @filesMinifier? and @filesCompressor?


	loadFiles: (callback) =>
		console.log 'loading files'
		@filesLoader.load (error, files) =>
			if error?
				callback error
			else
				@_files = files

				if process.env.NODE_ENV is 'production'
					console.log 'minifying files'
					@filesMinifier.replaceWithMinifiedFiles @_files

				console.log 'compressing files'
				@filesCompressor.addCompressedFiles @_files, callback


	getFiles: () =>
		assert.ok @_files?
		return @_files
