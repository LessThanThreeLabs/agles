window.RepositoryContent = {}


class RepositoryContent.Model extends Backbone.Model
	default:
		repositoryId: null
		mode: null

	initialize: () ->
		@repositoryBuildsModel = new RepositoryBuilds.Model repositoryId: @get 'repositoryId'

		@on 'change:repositoryId', () =>
			@repositoryBuildsModel.set 'repositoryId', @get 'repositoryId'


class RepositoryContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryContent'

	initialize: () =>
		@model.on 'change:mode', @render


	render: () =>
		@_renderCurrentView()
		return @


	_renderCurrentView: () =>
		switch @model.get 'mode'
			when 'builds'
				repositoryBuildsView = new RepositoryBuilds.View model: @model.repositoryBuildsModel
				@$el.html repositoryBuildsView.render().el
