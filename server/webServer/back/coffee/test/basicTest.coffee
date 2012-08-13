zombie = require 'zombie'
assert = require 'assert'


runTests = () ->
	runRedirectTest()


runRedirectTest = () ->
	browser = new zombie()

	browser.on 'error', (error) ->
		console.error error

	browser.visit('http://127.0.0.1')
		.then () ->
			assert.equals browser.location.href == 'https://127.0.0.1:443'

runTests()
