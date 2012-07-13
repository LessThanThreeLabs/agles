http = require 'http'


port = 8888

exports.start = ->
	http.createServer (request, response) ->
		response.writeHead 200, 'Content-Type': 'text/plain'
		response.write 'sup nerd'
		response.end()
	.listen port
	console.log 'Server running on ' + port