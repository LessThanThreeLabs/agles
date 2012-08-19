exports.create = (request, response) ->
	response.send 'create'

exports.show = (request, response) ->
	response.send request.context

exports.edit = (request, response) ->
	response.send 'edit'

exports.destroy = (request, response) ->
	response.send 'destroy'