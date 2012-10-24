window.BuildsSearchFilterType = class BuildsSearchFilterType
	constructor: (@name, @title, @description, @imageSource) ->
		assert.ok @name? and @title? and @description? and @imageSource?
