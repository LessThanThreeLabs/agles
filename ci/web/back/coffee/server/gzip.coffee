module.exports = () ->
	return (request, response, next) ->
		request.gzipAllowed = canUseGzip request.headers
		next()


canUseGzip = (headers) =>
	return false if not headers['accept-encoding']?
	return true if headers['accept-encoding'].trim() is '*'

	encodings = headers['accept-encoding'].split ','
	return encodings.some (encoding) =>
		return encoding is 'gzip'
