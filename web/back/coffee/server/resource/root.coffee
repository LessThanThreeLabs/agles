exports.index = (request, response) ->
	rootStaticDirectory = request.context.config.server.staticFiles.rootDirectory
	response.send '<html><head><script src="js/jquery.js"></script></head><body>' + request.session._csrf + '</body></html>'
	# replace with handlebars
	# response.send request.session._csrf
	# response.sendfile rootStaticDirectory + '/index.html'