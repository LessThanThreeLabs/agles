assert = require 'assert'


exports.generateCsrfToken = (session) ->
	assert.ok session?

	tokenBuffer = []
	characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
	for num in [0...24]
		randomCharacterIndex = Math.floor Math.random() * characters.length
		tokenBuffer.push characters[randomCharacterIndex]

	session.csrfToken = tokenBuffer.join ''
	