assert = require 'assert'


exports.setCsrfTokenIfMissing = (session) ->
	assert.ok session?
	if not session.csrfToken?
		session.csrfToken = generateCsrfToken()


generateCsrfToken = () ->
	characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
	
	tokenBuffer = []
	for num in [0...32]
		randomCharacterIndex = Math.floor Math.random() * characters.length
		tokenBuffer.push characters[randomCharacterIndex]

	return tokenBuffer.join ''
	