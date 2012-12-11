fs = require 'fs'
assert = require 'assert'
uglify = require 'uglify-js'


exports.create = (configurationParams) ->
	return new FilesMinifier configurationParams


class FilesMinifier
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	replaceWithMinifiedFiles: (files) =>
		console.log 'Minifying files...'
		@_minifyJs files
		@_minifyCss files


	_minifyJs: (files) =>
		jsFiles = @_flattenFiles files, 'js'
		minifiedJs = uglify.minify jsFiles, fromString: true

		files['js'] = []
		files['js'].push
			name: '/js/minified.js'
			plain: minifiedJs.code
			contentType: 'application/javascript'


	_minifyCss: (files) =>
		cssFiles = @_flattenFiles files, 'css'
		console.log 'need to minify css'


	_flattenFiles: (files, fileType) =>
		toReturn = []

		for file in files[fileType]
			toReturn.push file.plain

		return toReturn
