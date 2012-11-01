window.socket = io.connect 'https://' + window.location.host + '?csrfToken=' + window.csrfToken, resource: 'socket'
window.socket.on 'news', (data) ->
	console.log data
	socket.emit 'my other event', my: 'data'
