window.RepositoryAdminMenuOption = class RepositoryAdminMenuOption
	constructor: (@name, @title) ->
		assert.ok @name? and @title?