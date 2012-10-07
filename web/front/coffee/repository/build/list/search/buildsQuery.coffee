window.BuildsQuery = class BuildsQuery
	constructor: (@repositoryId, @type, @queryString, @start, @end) ->
		assert.ok @repositoryId? and @type? and @queryString? and @start? and @end?
