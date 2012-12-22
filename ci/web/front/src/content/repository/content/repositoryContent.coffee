window.RepositoryContent = {}


class RepositoryContent.Model extends Backbone.Model

	initialize: () =>
		@repositoryChangesModel = new RepositoryChanges.Model()
		@repositoryAdminModel = new RepositoryAdmin.Model()


class RepositoryContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryContent'
	html: ''
	currentView: null


	initialize: () =>
		globalRouterModel.on 'change:repositoryView', @_updateContent, @


	onDispose: () =>
		globalRouterModel.off null, null, @
		@currentView.dispose() if @currentView?


	render: () =>
		@_updateContent()
		return @


	_updateContent: () =>
		@currentView.dispose() if @currentView?

		switch globalRouterModel.get 'repositoryView'
			when 'changes'
				@currentView = new RepositoryChanges.View model: @model.repositoryChangesModel
				@$el.html @currentView.render().el
			when 'admin'
				@currentView = new RepositoryAdmin.View model: @model.repositoryAdminModel
				@$el.html @currentView.render().el
			when null
				# repository view hasn't been selected yet
				@$el.html '&nbsp'
			else
				@$el.html '&nbsp'
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'repositoryView'
