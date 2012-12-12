fs = require 'fs'
assert = require 'assert'


exports.create = (configurationParams, filesToLoadUri) ->
	return new FilesLoader configurationParams, filesToLoadUri


class FilesLoader
	constructor: (@configurationParams, @filesToLoadUri) ->
		assert.ok @configurationParams? and @filesToLoadUri?


	load: (callback) =>
		fs.readFile @filesToLoadUri, 'ascii', (error, filesToLoad) =>
			if error?
				callback error
			else
				files = @_createFiles filesToLoad
				@_loadFileContent files, callback


	_createFiles: (filesToLoad) =>
		files = {}

		for fileType, contentTypes of filesToLoad
			files[fileType] = {}

			for contentType, fileNames of contentTypes
				for fileName in fileNames
					files[fileType][fileName] = {}
					files[fileType][fileName].contentType = contentType
					files[fileType][fileName].location = @_getFileLocation fileName

		return files


	_loadFileContent: (files, callback) =>
		await
			for fileType of files
				for fileName, file of fileType
					fs.readFile file.location, 'binary', defer file.error, file.plain

		combinedErrors = ''
		for fileType of files
			for fileName, file of files[fileType]
				combinedErrors += file.error + ' ' if file.error?

		if combinedErrors isnt ''
			callback combinedErrors
		else
			callback null, files


	_getFileLocation: (fileName) =>
		return @configurationParams.staticFiles.rootDirectory + fileName
