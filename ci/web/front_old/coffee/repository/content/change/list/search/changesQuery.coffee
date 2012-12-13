window.ChangesQuery = class ChangesQuery
	constructor: (@repositoryId, @queryString, @startNumber, @numberToRetrieve) ->
		assert.ok @repositoryId? and @queryString? and @startNumber? and @numberToRetrieve?
