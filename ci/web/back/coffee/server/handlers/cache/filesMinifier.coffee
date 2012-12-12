fs = require 'fs'
assert = require 'assert'
uglifyJs = require 'uglify-js'
cleanCss = require 'clean-css'


exports.create = (configurationParams) ->
	return new FilesMinifier configurationParams


class FilesMinifier
	constructor: (@configurationParams) ->
		assert.ok @configurationParams?


	replaceWithMinifiedFiles: (files) =>
		@_replaceJs files
		@_replaceCss files


	_replaceJs: (files) =>
		minifiedJsCode = @_getMinifiedJs files.js

		minifiedJsFile =
			plain: minifiedJsCode
			contentType: 'application/javascript'

		files.js = {}
		files.js['/js/minified.js'] = minifiedJsFile


	_getMinifiedJs: (jsFiles) =>
		topLevelAst = null
		for jsFileName, jsFile of jsFiles
			topLevelAst = uglifyJs.parse jsFile.plain,
				filename: jsFile.name
				toplevel: topLevelAst

		topLevelAst.figure_out_scope()

		compressor = uglifyJs.Compressor warnings: false
		compressedAst = topLevelAst.transform compressor

		compressedAst.figure_out_scope()
		compressedAst.compute_char_frequency()
		compressedAst.mangle_names()

		return compressedAst.print_to_string
			 comments: (node, commentToken) =>
			 	return commentToken.type is 'comment2'


	_replaceCss: (files) =>
		minifiedCssCode = @_getMinifiedCss files.css

		minifiedCssFile =
			plain: minifiedCssCode
			contentType: 'text/css'

		files.css = {}
		files.css['/css/minified.css'] = minifiedCssFile


	_getMinifiedCss: (cssFiles) =>
		minifiedCssToCombine = []
		for cssFileName, cssFile of cssFiles
			minifiedCss = cleanCss.process cssFile.plain, removeEmpty: true
			minifiedCssToCombine.push minifiedCss

		return minifiedCssToCombine.join ' '
