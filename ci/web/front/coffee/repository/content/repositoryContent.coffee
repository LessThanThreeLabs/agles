window.RepositoryContent = {}


class RepositoryContent.Model extends Backbone.Model

	initialize: () =>
		@repositoryBuildsModel = new RepositoryBuilds.Model()
		@repositoryAdminModel = new RepositoryAdmin.Model()


class RepositoryContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryContent'
	currentView: null


	initialize: () =>
		window.globalRouterModel.on 'change:repositoryView', @_updateContent


	onDispose: () =>
		window.globalRouterModel.off null, null, @
		@currentView.dispose() if @currentView?


	render: () =>
		@_updateContent()
		return @


	_updateContent: () =>
		@currentView.dispose() if @currentView?

		switch window.globalRouterModel.get 'repositoryView'
			when 'builds'
				@currentView = new RepositoryBuilds.View model: @model.repositoryBuildsModel
				@$el.html @currentView.render().el
			when 'admin'
				@currentView = new RepositoryAdmin.View model: @model.repositoryAdminModel
				@$el.html @currentView.render().el
			when null
				# repository view hasn't been selected yet
				@currentView = null
				@$el.html '&nbsp'
			else
				@currentView = null
				@$el.html '&nbsp'
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'repositoryView'
