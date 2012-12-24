assert = require 'assert'


exports.create = (configurationParams) ->
	return new StaticServer configurationParams


class StaticServer
	_files: {}

	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	addFiles: (filesToAdd) =>
		for fileType, files of filesToAdd
			# @_files[fileType] = {} if not @_files[fileType]?

			for fileName, file of files
				existingFile = @_files[fileName]
				if existingFile?
					assert @_checkFilesAreSame existingFile, file
				else
					@_files[fileName] = file


	_checkFilesAreSame: (file1, file2) =>
		for key, value of file1
			continue if not value?
			if file2[key].toString() isnt value.toString()
				return false

		for key, value of file2
			continue if not value?
			if file1[key].toString() isnt value.toString()
				return false

		return true


	handleRequest: (request, response) =>
		if @_files[request.path]?
			@_sendFile request, response, @_files[request.path]
		else
			response.send 'pretty 404 here...'


	_sendFile: (request, response, file) =>
		if request.gzipAllowed and file.gzip?
			response.writeHead 200,
				'content-type': file.contentType
				'content-encoding': 'gzip'
			response.end file.gzip, 'binary'
		else
			response.writeHead 200,
				'content-type': file.contentType
			response.end file.plain, 'binary'
