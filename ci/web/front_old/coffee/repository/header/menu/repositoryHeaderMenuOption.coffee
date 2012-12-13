window.RepositoryHeaderMenuOption = class RepositoryHeaderMenuOption
	constructor: (@name, @tooltipText, @imageSource) ->
		assert.ok @name? and @tooltipText? and @imageSource?
