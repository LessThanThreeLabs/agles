fs = require 'fs'
zlib = require 'zlib'
assert = require 'assert'

FilesLoader = require './filesLoader'
FilesMinifier = require './filesMinifier'


exports.create = (configurationParams) ->
	filesLoader = FilesLoader.create configurationParams
	filesMinifier = FilesMinifier.create configurationParams
	return new FilesCacher configurationParams, filesLoader, filesMinifier


class FilesCacher
	_files: null

	constructor: (@configurationParams, @filesLoader, @filesMinifier) ->
		assert.ok @configurationParams? and @filesLoader? and @filesMinifier?


	loadFiles: (callback) =>
		@filesLoader.load (error, files) =>
			if error?
				callback error
			else
				@_files = files

				@_switchToMinifiedVersions (error) =>
					if error?
						callback error
						return

					@_addCompressedFiles (error) =>
						if error?
							callback error
							return

					callback()


	_switchToMinifiedVersions: (callback) =>
		@filesMinifier.minifyJs @_files, (error, minifiedJs) =>
			if error?
				callback error
				return

			@_files['js'] = []
			@_files['js'].push
				name: '/js/minified.js'
				plain: minifiedJs
				contentType: 'application/javascript'

			callback()


	_addCompressedFiles: (callback) =>
		gzipErrors = {}

		await
			for fileType of @_files
				gzipErrors[fileType] = []
				for file, index in @_files[fileType]
					continue if not @_shouldGzip file.contentType
					zlib.gzip file.plain, defer gzipErrors[fileType][index], @_files[fileType][index].gzip

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
		assert.ok @_files?
		return Object.keys @_files


	getFiles: (fileType) =>
		assert.ok @_files?
		return @_files[fileType]


	getMinifiedJavascript: () =>
		return @minifiedJavascript
