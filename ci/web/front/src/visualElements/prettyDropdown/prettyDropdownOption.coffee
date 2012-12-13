window.PrettyDropdownOption = class PrettyDropdownOption
	constructor: (@name, @title) ->
		assert.ok @name? and @title?