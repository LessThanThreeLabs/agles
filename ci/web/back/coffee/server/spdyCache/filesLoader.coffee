fs = require 'fs'
assert = require 'assert'


exports.create = (configurationParams) ->
	return new FilesLoader configurationParams


class FilesLoader
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	load: (callback) =>
		@_determineFilesToCache callback


	_determineFilesToCache: (callback) =>
		fs.readFile @configurationParams.staticFiles.spdy.filesToCacheFile, 'ascii', (error, file) =>
			if error?
				callback error
			else 
				filesToLoad = JSON.parse file
				@_loadFiles filesToLoad, callback


	_loadFiles: (filesToLoad, callback) =>
		loadedFiles = {}
		loadedFileErrors = {}

		await
			for fileType, contentTypes of filesToLoad
				@_loadFilesForContentTypes contentTypes, defer loadedFileErrors[fileType], loadedFiles[fileType] 

		anyErrors = false
		for fileType, error of loadedFileErrors
			anyErrors = true if error?

		if anyErrors then callback JSON.stringify loadedFileErrors
		else callback null, loadedFiles


	_loadFilesForContentTypes: (contentTypes, callback) =>
		loadedFiles = []
		loadedFileErrors = []
		index = 0

		await
			for contentType, files of contentTypes
				for fileName in files
					loadedFiles[index] = {}
					loadedFiles[index].name = fileName
					loadedFiles[index].contentType = contentType
					fs.readFile @_getFileLocation(fileName), 'binary', defer loadedFileErrors[index], loadedFiles[index].plain
					++index

		combinedErrors = loadedFileErrors.reduce ((previous, current) =>
				return previous + ' ' + (current ? '')
			), ''
		trimmedErrors = combinedErrors.trim()

		if trimmedErrors isnt '' then callback trimmedErrors
		else callback null, loadedFiles


	_getFileLocation: (fileName) =>
		return @configurationParams.staticFiles.rootDirectory + fileName
