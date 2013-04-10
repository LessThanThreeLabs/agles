assert = require 'assert'


module.exports = class Emailer
	constructor: (@configurationParams, @emailSender, @domainRetriever) ->
		assert.ok @configurationParams?
		assert.ok @emailSender?
		assert.ok @domainRetriever?


	getDomain: (callback) =>
		@domainRetriever.getDomain callback
		