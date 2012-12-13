window.RepositoryContent = {}


class RepositoryContent.Model extends Backbone.Model

	initialize: () =>
		@repositoryChangesModel = new RepositoryChanges.Model()
		@repositoryAdminModel = new RepositoryAdmin.Model()


class RepositoryContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryContent'


	initialize: () =>
		@repositoryChangesView = new RepositoryChanges.View model: @model.repositoryChangesModel
		@repositoryAdminView = new RepositoryAdmin.View model: @model.repositoryAdminModel

		globalRouterModel.on 'change:repositoryView', @_updateContent, @


	onDispose: () =>
		globalRouterModel.off null, null, @
		
		@repositoryChangesView.dispose()
		@repositoryAdminView.dispose()


	render: () =>
		@_updateContent()
		return @


	_updateContent: () =>
		switch globalRouterModel.get 'repositoryView'
			when 'changes'
				@$el.html @repositoryChangesView.render().el
			when 'admin'
				@$el.html @repositoryAdminView.render().el
			when null
				# repository view hasn't been selected yet
				@$el.html '&nbsp'
			else
				@$el.html '&nbsp'
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'repositoryView'
