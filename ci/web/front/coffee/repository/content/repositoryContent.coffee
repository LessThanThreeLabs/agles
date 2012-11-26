window.RepositoryContent = {}


class RepositoryContent.Model extends Backbone.Model

	initialize: () ->
		@repositoryBuildsModel = new RepositoryBuilds.Model()
		@repositoryAdminModel = new RepositoryAdmin.Model()


class RepositoryContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryContent'

	initialize: () =>
		window.globalRouterModel.on 'change:repositoryView', @_renderCurrentView


	render: () =>
		@_renderCurrentView()
		return @


	_renderCurrentView: () =>
		switch window.globalRouterModel.get 'repositoryView'
			when 'builds'
				repositoryBuildsView = new RepositoryBuilds.View model: @model.repositoryBuildsModel
				@$el.html repositoryBuildsView.render().el
			when 'admin'
				repositoryAdminView = new RepositoryAdmin.View model: @model.repositoryAdminModel
				@$el.html repositoryAdminView.render().el
			when null
				# repository view hasn't been selected yet
			else
				console.error 'Unaccounted for mode ' + window.globalRouterModel.get 'repositoryView'
