window.RepositoryBuilds = {}


class RepositoryBuilds.Model extends Backbone.Model

	initialize: () =>
		@buildsListManagerModel = new BuildsListManager.Model()
		@buildDetailsModel = new BuildDetails.Model()


class RepositoryBuilds.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryBuilds'
	html: ''


	initialize: () =>
		@buildsListManagerView = new BuildsListManager.View model: @model.buildsListManagerModel
		@buildDetailsView = new BuildDetails.View model: @model.buildDetailsModel


	onDispose: () =>
		@buildsListManagerView.dispose()
		@buildDetailsView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @buildsListManagerView.render().el
		@$el.append @buildDetailsView.render().el
		return @
