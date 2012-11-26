window.RepositoryBuilds = {}


class RepositoryBuilds.Model extends Backbone.Model

	initialize: () ->
		@buildsListManagerModel = new BuildsListManager.Model()
		@buildDetailsModel = new BuildDetails.Model()


class RepositoryBuilds.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryBuilds'
	template: Handlebars.compile ''

	initialize: () ->

	render: () ->
		@$el.html @template()

		buildsListManagerView = new BuildsListManager.View model: @model.buildsListManagerModel
		@$el.append buildsListManagerView.render().el

		buildDetailsView = new BuildDetails.View model: @model.buildDetailsModel
		@$el.append buildDetailsView.render().el
		return @
