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
		@_replaceJs files
		@_replaceCss files


	_replaceJs: (files) =>
		jsFiles = @_flattenFiles files, 'js'
		minifiedJs = @_getMinifiedJs jsFiles

		files['js'] = []
		files['js'].push
			name: '/js/minified.js'
			plain: minifiedJs
			contentType: 'application/javascript'


	_getMinifiedJs: (jsFiles) =>
		topLevelAst = null
		for jsFile in jsFiles
			topLevelAst = uglify.parse jsFile.plain,
				filename: jsFile.name
				toplevel: topLevelAst

		topLevelAst.figure_out_scope()

		compressor = uglify.Compressor warnings: false
		compressedAst = topLevelAst.transform compressor

		compressedAst.figure_out_scope()
		compressedAst.compute_char_frequency()
		compressedAst.mangle_names()

		return compressedAst.print_to_string
			 comments: (node, commentToken) =>
			 	return commentToken.type is 'comment2'


	_replaceCss: (files) =>
		cssFiles = @_flattenFiles files, 'css'
		console.log 'need to minify css'


	_flattenFiles: (files, fileType) =>
		toReturn = []

		for file in files[fileType]
			toReturn.push file

		return toReturn
