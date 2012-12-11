fs = require 'fs'
zlib = require 'zlib'
assert = require 'assert'

FilesLoader = require './filesLoader'
FilesMinifier = require './filesMinifier'
FilesCompressor = require './filesCompressor'


exports.create = (configurationParams) ->
	filesLoader = FilesLoader.create configurationParams
	filesMinifier = FilesMinifier.create configurationParams
	filesCompressor = FilesCompressor.create configurationParams
	return new FilesCacher configurationParams, filesLoader, filesMinifier, filesCompressor


class FilesCacher
	_files: null

	constructor: (@configurationParams, @filesLoader, @filesMinifier, @filesCompressor) ->
		assert.ok @configurationParams? and @filesLoader? and @filesMinifier? and @filesCompressor?


	loadFiles: (callback) =>
		@filesLoader.load (error, files) =>
			if error?
				callback error
			else
				@_files = files

				if true
					@filesMinifier.replaceWithMinifiedFiles @_files

				@filesCompressor.addCompressedFiles @_files, callback


	getFileTypes: () =>
		assert.ok @_files?
		return Object.keys @_files


	getFiles: (fileType) =>
		assert.ok @_files?
		return @_files[fileType]
