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
			for fileType in Object.keys filesToCache
				loadedFiles[fileType] = []
				loadedFileErrors[fileType] = []

				for fileName, index in filesToCache[fileType]
					loadedFiles[fileType][index] = {}
					loadedFiles[fileType][index].name = fileName
					fs.readFile @_getFileLocation(fileName), 'ascii', defer loadedFileErrors[fileType][index], loadedFiles[fileType][index].plainText		

		if @_containsAnyErrors loadedFileErrors
			callback 'Unable to load all the files'
		else
			callback null, loadedFiles


	_containsAnyErrors: (loadedFileErrors) =>
		for fileType in Object.keys loadedFileErrors
			anyErrors = loadedFileErrors[fileType].some (fileError) =>
				return fileError?
			return true if anyErrors

		return false


	_getFileLocation: (fileName) =>
		return @configurationParams.staticFiles.rootDirectory + '/' + fileName