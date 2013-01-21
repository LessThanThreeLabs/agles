window.ChangesQuery = class ChangesQuery
	constructor: (@repositoryId, @queryString, @startNumber, @numberToRetrieve) ->
		assert.ok @repositoryId?
		assert.ok @queryString?
		assert.ok @startNumber?
		assert.ok @numberToRetrieve?
