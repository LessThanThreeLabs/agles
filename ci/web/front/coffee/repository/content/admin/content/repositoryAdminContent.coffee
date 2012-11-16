window.RepositoryAdminContent = {}


class RepositoryAdminContent.Model extends Backbone.Model
	defaults:
		repositoryId: null

	initialize: () ->


class RepositoryAdminContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminContent'
	template: Handlebars.compile 'content will go here'

	initialize: () ->

	render: () ->
		@$el.html @template()
		return @
