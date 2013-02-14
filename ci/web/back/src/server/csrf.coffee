module.exports = () ->
	return (request, response, next) ->
		request.session?.csrfToken ?= generateCsrfToken()
		next()


generateCsrfToken = () ->
	characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
	
	tokenBuffer = []
	for num in [0...32]
		randomCharacterIndex = Math.floor Math.random() * characters.length
		tokenBuffer.push characters[randomCharacterIndex]

	return tokenBuffer.join ''
	