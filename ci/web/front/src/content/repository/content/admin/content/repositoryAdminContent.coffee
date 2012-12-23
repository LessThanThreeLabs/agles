window.RepositoryAdminContent = {}


class RepositoryAdminContent.Model extends Backbone.Model
	defaults:
		view: null


	initialize: () =>
		@generalPanelModel = new RepositoryAdminGeneralPanel.Model()
		@membersPanelModel = new RepositoryAdminMembersPanel.Model()
		@githubPanelModel = new RepositoryAdminGithubPanel.Model()


class RepositoryAdminContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminContent'
	currentView: null


	initialize: () =>
		@model.on 'change:view', @render, @


	onDispose: () =>
		@model.off null, null, @
		@currentView.dispose() if @currentView?


	render: () =>
		@_renderCurrentView()
		return @


	_renderCurrentView: () =>
		@currentView.dispose() if @currentView?

		switch @model.get 'view'
			when 'general'
				@currentView = new RepositoryAdminGeneralPanel.View model: @model.generalPanelModel
				@$el.html @currentView.render().el
			when 'members'
				@currentView = new RepositoryAdminMembersPanel.View model: @model.membersPanelModel
				@$el.html @currentView.render().el
			when 'github'
				@currentView = new RepositoryAdminGithubPanel.View model: @model.githubPanelModel
				@$el.html @currentView.render().el
			else
				@currentView = null
				@$el.html '&nbsp'
				console.error 'Unaccounted for mode ' + @model.get 'view' if @model.get('view')?
