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


	_loadFiles: (filesToCache, callback) =>
		loadedFiles = {}
		loadedFileErrors = {}

		await
			for fileType, contentTypes of filesToCache
				@_loadFilesForContentTypes fileType, contentTypes, defer loadedFileErrors[fileType], loadedFiles[fileType] 

		anyErrors = false
		for fileType, error of loadedFileErrors
			anyErrors = true if error?

		if anyErrors then callback 'Unable to load files'
		else callback null, loadedFiles


	_loadFilesForContentTypes: (fileType, contentTypes, callback) =>
		loadedFiles = []
		loadedFileErrors = []

		await
			for contentType, files of contentTypes
				for fileName, index in files
					loadedFiles[index] = {}
					loadedFiles[index].name = fileName
					loadedFiles[index].contentType = contentType
					fs.readFile @_getFileLocation(fileName), @_getFileEncoding(fileType), defer loadedFileErrors[index], loadedFiles[index].plain

		anyErrors = loadedFileErrors.some (fileError) =>
			return fileError?

		if anyErrors then callback 'Unable to load files'
		else callback null, loadedFiles


	_getFileLocation: (fileName) =>
		return @configurationParams.staticFiles.rootDirectory + '/' + fileName


	_getFileEncoding: (fileType) =>
		if fileType is 'css' or fileType is 'js'
			return 'ascii'
		else
			return 'binary'
