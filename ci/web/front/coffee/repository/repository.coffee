window.Repository = {}


class Repository.Model extends Backbone.Model
	default:
		repositoryId: null
		repositoryMode: null

	initialize: () ->
		@repositoryHeaderModel = new RepositoryHeader.Model repositoryId: @get 'repositoryId'
		@repositoryContentModel = new RepositoryContent.Model repositoryId: @get 'repositoryId'

		@repositoryHeaderModel.on 'change:mode', () =>
			@repositoryContentModel.set 'mode', @repositoryHeaderModel.get 'mode'

		@on 'change:repositoryId', () =>
			@repositoryHeaderModel.set 'repositoryId', @get 'repositoryId'
			@repositoryContentModel.set 'repositoryId', @get 'repositoryId'
		@on 'change:repositoryMode', () =>
			@repositoryHeaderModel.set 'mode', @get 'repositoryMode'


	validate: (attributes) =>
		if not attributes.repositoryId?
			return new Error 'Invalid repository id'
		return


class Repository.View extends Backbone.View
	tagName: 'div'
	className: 'repository'
	template: Handlebars.compile ''

	initialize: () ->
		@repositoryHeaderView = new RepositoryHeader.View model: @model.repositoryHeaderModel
		@repositoryContentView = new RepositoryContent.View model: @model.repositoryContentModel


	render: () ->
		@$el.html @template()
		@$el.append @repositoryHeaderView.render().el
		@$el.append @repositoryContentView.render().el
		return @
