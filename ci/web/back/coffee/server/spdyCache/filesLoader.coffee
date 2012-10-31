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
				@_loadFilesForContentTypes contentTypes, defer loadedFileErrors[fileType], loadedFiles[fileType] 

		anyErrors = false
		for fileType, error of loadedFileErrors
			anyErrors = true if error?

		if anyErrors then callback 'Unable to load files'
		else callback null, loadedFiles


	_loadFilesForContentTypes: (contentTypes, callback) =>
		loadedFiles = []
		loadedFileErrors = []

		await
			for contentType, files of contentTypes
				for fileName, index in files
					loadedFiles[index] = {}
					loadedFiles[index].name = fileName
					loadedFiles[index].contentType = contentType
					fs.readFile @_getFileLocation(fileName), 'ascii', defer loadedFileErrors[index], loadedFiles[index].plainText

		anyErrors = loadedFileErrors.some (fileError) =>
			return fileError?

		if anyErrors then callback 'Unable to load files'
		else callback null, loadedFiles







	# _loadFiles: (filesToCache, callback) =>
	# 	loadedFiles = {}
	# 	loadedFileErrors = {}

	# 	await
	# 		for fileType in Object.keys filesToCache
	# 			loadedFiles[fileType] = []
	# 			loadedFileErrors[fileType] = []

	# 			for contentType of 
	# 				for fileName, index in filesToCache[fileType]
	# 				loadedFiles[fileType][index] = {}
	# 				loadedFiles[fileType][index].name = fileName
	# 				fs.readFile @_getFileLocation(fileName), 'ascii', defer loadedFileErrors[fileType][index], loadedFiles[fileType][index].plainText		

	# 	if @_containsAnyErrors loadedFileErrors
	# 		callback 'Unable to load all the files'
	# 	else
	# 		callback null, loadedFiles


	# _containsAnyErrors: (loadedFileErrors) =>
	# 	for fileType in Object.keys loadedFileErrors
	# 		anyErrors = loadedFileErrors[fileType].some (fileError) =>
	# 			return fileError?
	# 		return true if anyErrors

	# 	return false


	_getFileLocation: (fileName) =>
		return @configurationParams.staticFiles.rootDirectory + '/' + fileName