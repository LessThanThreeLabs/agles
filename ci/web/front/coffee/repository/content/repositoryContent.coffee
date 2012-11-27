window.RepositoryContent = {}


class RepositoryContent.Model extends Backbone.Model

	initialize: () =>
		


class RepositoryContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryContent'


	initialize: () =>
		window.globalRouterModel.on 'change:repositoryView', @render


	render: () =>
		@$el.html '&nbsp'

		switch window.globalRouterModel.get 'repositoryView'
			when 'builds'
				repositoryBuildsModel = new RepositoryBuilds.Model()
				repositoryBuildsView = new RepositoryBuilds.View model: repositoryBuildsModel
				@$el.html repositoryBuildsView.render().el
			when 'admin'
				repositoryAdminModel = new RepositoryAdmin.Model()
				repositoryAdminView = new RepositoryAdmin.View model: repositoryAdminModel
				@$el.html repositoryAdminView.render().el
			when null
				# repository view hasn't been selected yet
			else
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'repositoryView'

		return @
