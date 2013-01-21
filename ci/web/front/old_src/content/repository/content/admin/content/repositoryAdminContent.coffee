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
	_currentView: null
	_rendered: false


	initialize: () =>
		@model.on 'change:view', @_renderCurrentView, @


	onDispose: () =>
		@model.off null, null, @
		@_currentView.dispose() if @_currentView?


	render: () =>
		@_rendered = true
		@_renderCurrentView()
		return @


	_renderCurrentView: () =>
		@_currentView.dispose() if @_currentView?
		return if not @_rendered

		switch @model.get 'view'
			when 'general'
				@_currentView = new RepositoryAdminGeneralPanel.View model: @model.generalPanelModel
				@$el.html @_currentView.render().el
			when 'members'
				@_currentView = new RepositoryAdminMembersPanel.View model: @model.membersPanelModel
				@$el.html @_currentView.render().el
			when 'github'
				@_currentView = new RepositoryAdminGithubPanel.View model: @model.githubPanelModel
				@$el.html @_currentView.render().el
			else
				@_currentView = null
				@$el.html '&nbsp'
				console.error 'Unaccounted for mode ' + @model.get 'view' if @model.get('view')?
