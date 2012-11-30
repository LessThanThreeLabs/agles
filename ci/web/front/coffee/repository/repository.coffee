window.Repository = {}


class Repository.Model extends Backbone.Model

	initialize: () =>
		@repositoryHeaderModel = new RepositoryHeader.Model()
		@repositoryContentModel = new RepositoryContent.Model()


class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	html: ''


	initialize: () =>
		@repositoryHeaderView = new RepositoryHeader.View model: @model.repositoryHeaderModel
		@repositoryContentView = new RepositoryContent.View model: @model.repositoryContentModel


	onDispose: () =>
		@repositoryHeaderView.dispose()
		@repositoryContentView.dispose()


	render: () =>
		@$el.html @html
		@$el.append @repositoryHeaderView.render().el
		@$el.append @repositoryContentView.render().el
		return @
