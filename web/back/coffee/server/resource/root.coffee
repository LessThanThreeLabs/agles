exports.index = (request, response) ->
	rootStaticDirectory = request.context.config.server.staticFiles.rootDirectory
	response.sendfile rootStaticDirectory + '/index.html'