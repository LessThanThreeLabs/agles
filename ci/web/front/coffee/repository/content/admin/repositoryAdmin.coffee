window.RepositoryAdmin = {}


class RepositoryAdmin.Model extends Backbone.Model
	default:
		repositoryId: null

	initialize: () ->
		@on 'change:repositoryId', () =>


class RepositoryAdmin.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdmin'
	template: Handlebars.compile 'Hello'

	initialize: () ->

	render: () ->
		@$el.html @template()
		return @
