exports.index = (request, response) ->
	response.render 'index', csrfToken: request.session._csrf
