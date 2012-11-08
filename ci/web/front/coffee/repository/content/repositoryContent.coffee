window.RepositoryContent = {}


class RepositoryContent.Model extends Backbone.Model
	default:
		repositoryId: null

	initialize: () ->
		@on 'change:repositoryId', () =>
			# @repositoryHeaderModel.set 'repositoryId', @get 'repositoryId'


	validate: (attributes) =>
		if not attributes.repositoryId?
			return false
		return


class RepositoryContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryContent'
	template: Handlebars.compile ''

	initialize: () ->

	render: () ->
		@$el.html @template()
		return @
