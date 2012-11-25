window.Repository = {}


class Repository.Model extends Backbone.Model

	initialize: () ->
		@repositoryHeaderModel = new RepositoryHeader.Model()
		@repositoryContentModel = new RepositoryContent.Model()


class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	template: Handlebars.compile ''

	render: () ->
		@$el.html @template()
		
		repositoryHeaderView = new RepositoryHeader.View model: @model.repositoryHeaderModel
		@$el.append repositoryHeaderView.render().el
		
		repositoryContentView = new RepositoryContent.View model: @model.repositoryContentModel
		@$el.append repositoryContentView.render().el

		return @
