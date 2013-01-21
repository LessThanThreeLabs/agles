window.PrettyMenuOption = class PrettyMenuOption
	constructor: (@name, @title) ->
		assert.ok @name?
		assert.ok @title?