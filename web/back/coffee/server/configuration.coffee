fs = require 'fs'
assert = require 'assert'
fileWalker = require 'walk'
express = require 'express'


exports.create = (configurationParams, sessionStore) ->
	return new ServerConfigurer configurationParams, sessionStore


class ServerConfigurer
	constructor: (@configurationParams, @sessionStore) ->
		assert.ok @configurationParams? and @sessionStore?


	getConfigurationParams: () ->
		return @configurationParams


	configure: (server) ->
		server.configure () =>
			# ORDER HERE IS VERY IMPORTANT!!!!
			server.use express.cookieParser()
			server.use express.bodyParser()  # need this?
			server.use express.query()  # need this?
			server.use express.compress()
			@_configureSessionLogic server
			@_configureViewEngine server
			@_configureStaticServer server

		server.configure 'development', () ->
			server.use express.errorHandler 
				dumpExceptions: true,
				showStack: true


	_configureViewEngine: (server) ->
		server.set 'view engine', 'hbs'
		server.set 'view options', layout: false
		server.set 'views', @configurationParams.staticFiles.rootDirectory


	_configureStaticServer: (server) ->
		server.use express.favicon @configurationParams.staticFiles.rootDirectory + '/favicon.ico'

		server.use express.staticCache
			maxObjects: @configurationParams.staticFiles.cache.maxObjects
			maxLength: @configurationParams.staticFiles.cache.maxLength

		for staticDirectory in @configurationParams.staticFiles.staticDirectories
			server.use staticDirectory,
				express.static @configurationParams.staticFiles.rootDirectory + staticDirectory, maxAge: 0
				# TODO: determine correct maxage!!!!


	_configureSessionLogic: (server) ->
		server.use express.session
	    	secret: @configurationParams.session.secret
	    	cookie:
	    		key: @configurationParams.session.cookie.name
	    		path: '/',
	    		httpOnly: true,
	    		secure: true,
	    		maxAge: 14400000
	    	store: @sessionStore

		@_ignoreStaticFilesFromSessionLogic()


	_ignoreStaticFilesFromSessionLogic: () ->
		console.log '_ignoreStaticBlah has sideeffects!!!! '

		express.session.ignore.push '/favicon.ico'

		rootDirectory = @configurationParams.staticFiles.rootDirectory
		staticDirectories = @configurationParams.staticFiles.staticDirectories

		for staticDirectory in staticDirectories
			directory = rootDirectory + staticDirectory

			walker = fileWalker.walkSync directory, followLinks: true

			walker.on 'file', (root, fileStats, next) ->
				fileToIgnore = root + '/' + fileStats.name
				staticFileToIgnore = fileToIgnore.substring fileToIgnore.indexOf staticDirectory
				express.session.ignore.push staticFileToIgnore
				next()

			walker.on 'end', () ->
				assert.ok express.session.ignore.length > 1,
					'Problem finding static files to ignore from session logic.'
