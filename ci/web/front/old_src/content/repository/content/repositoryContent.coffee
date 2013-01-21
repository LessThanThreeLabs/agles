window.RepositoryContent = {}


class RepositoryContent.Model extends Backbone.Model

	initialize: () =>
		@repositoryChangesModel = new RepositoryChanges.Model()
		@repositoryAdminModel = new RepositoryAdmin.Model()


class RepositoryContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryContent'
	html: ''
	_currentView: null
	_rendered: false


	initialize: () =>
		globalRouterModel.on 'change:repositoryView', @_updateContent, @


	onDispose: () =>
		globalRouterModel.off null, null, @
		@_currentView.dispose() if @_currentView?


	render: () =>
		@_rendered = true
		@_updateContent()
		return @


	_updateContent: () =>
		@_currentView.dispose() if @_currentView?
		return if not @_rendered

		switch globalRouterModel.get 'repositoryView'
			when 'changes'
				@_currentView = new RepositoryChanges.View model: @model.repositoryChangesModel
				@$el.html @_currentView.render().el
			when 'admin'
				@_currentView = new RepositoryAdmin.View model: @model.repositoryAdminModel
				@$el.html @_currentView.render().el
			when null
				# repository view hasn't been selected yet
				@$el.html '&nbsp'
			else
				@$el.html '&nbsp'
				console.error 'Unaccounted for view ' + window.globalRouterModel.get 'repositoryView'
