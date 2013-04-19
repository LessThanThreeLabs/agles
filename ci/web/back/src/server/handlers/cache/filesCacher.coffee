assert = require 'assert'
colors = require 'colors'

FilesLoader = require './filesLoader'
FilesMinifier = require './filesMinifier'
FilesCompressor = require './filesCompressor'


exports.create = (name, configurationParams, filesToLoadUri, filesSuffix, logger) ->
	filesLoader = FilesLoader.create configurationParams, filesToLoadUri, filesSuffix
	filesMinifier = FilesMinifier.create configurationParams
	filesCompressor = FilesCompressor.create configurationParams
	return new FilesCacher name, configurationParams, filesLoader, filesMinifier, filesCompressor


class FilesCacher
	_files: null

	constructor: (@name, @configurationParams, @filesLoader, @filesMinifier, @filesCompressor) ->
		assert.ok @name, @configurationParams? and @filesLoader? and @filesMinifier? and @filesCompressor?


	loadFiles: (callback) =>
		@filesLoader.load (error, files) =>
			console.log @name.cyan + ' - loaded files'.white
			if error?
				callback error
			else
				@_files = files
				@_minifyFiles callback


	_minifyFiles: (callback) =>
		if process.env.NODE_ENV is 'production'
			@filesMinifier.replaceWithMinifiedFiles @_files, (error) =>
				console.log @name.cyan + ' - minified files'.white
				if error?
					callback error
				else
					@_compressFiles callback
		else
			@_compressFiles callback


	_compressFiles: (callback) =>
		@filesCompressor.addCompressedFiles @_files, callback
		console.log @name.cyan + ' - compressed files'.white


	getFiles: () =>
		assert.ok @_files?
		return @_files
