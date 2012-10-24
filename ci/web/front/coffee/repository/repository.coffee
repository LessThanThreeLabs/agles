window.Repository = {}


class Repository.Model extends Backbone.Model
	urlRoot: 'repositories'

	initialize: () ->
		@repositoryHeaderModel = new RepositoryHeader.Model repositoryId: @get 'id'
		@repositoryBuildsModel = new RepositoryBuilds.Model repositoryId: @get 'id'

		@on 'change', () =>
			@repositoryHeaderModel.set 'name', @get 'name'
			@repositoryHeaderModel.set 'subname', @get 'subname'


class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	template: Handlebars.compile '<div class="repositoryContents"></div>'

	initialize: () ->
		@repositoryHeaderView = new RepositoryHeader.View model: @model.repositoryHeaderModel
		@repositoryBuildsView = new RepositoryBuilds.View model: @model.repositoryBuildsModel


	render: () ->
		@$el.html @template()
		@$el.find('.repositoryContents').append @repositoryHeaderView.render().el
		@$el.find('.repositoryContents').append @repositoryBuildsView.render().el
		return @
