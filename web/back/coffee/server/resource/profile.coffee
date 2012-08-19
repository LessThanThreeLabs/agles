exports.create = (request, response) ->
	console.log 'create called!'
	response.send 'create'

exports.show = (request, response) ->
	response.send 'show'

exports.edit = (request, response) ->
	response.send 'edit'

exports.destroy = (request, response) ->
	response.send 'destroy'