window.SimpleMenuOption = class SimpleMenuOption
	constructor: (@name, @title) ->
		assert.ok @name? and @title?