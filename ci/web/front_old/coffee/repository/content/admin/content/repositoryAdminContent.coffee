window.RepositoryAdminContent = {}


class RepositoryAdminContent.Model extends Backbone.Model
	defaults:
		repositoryId: null
		mode: null


	initialize: () =>
		@generalPanelModel = new RepositoryAdminGeneralPanel.Model()
		@membersPanelModel = new RepositoryAdminMembersPanel.Model()


class RepositoryAdminContent.View extends Backbone.View
	tagName: 'div'
	className: 'repositoryAdminContent'
	currentView: null


	initialize: () =>
		@model.on 'change:mode', @render, @


	onDispose: () =>
		@model.off null, null, @
		@currentView.dispose() if @currentView?


	render: () =>
		@_renderCurrentView()
		return @


	_renderCurrentView: () =>
		@currentView.dispose() if @currentView?

		switch @model.get 'mode'
			when 'general'
				@currentView = new RepositoryAdminGeneralPanel.View model: @model.generalPanelModel
				@$el.html @currentView.render().el
			when 'members'
				@currentView = new RepositoryAdminMembersPanel.View model: @model.membersPanelModel
				@$el.html @currentView.render().el
			else
				@currentView = null
				@$el.html '&nbsp'
				console.error 'Unaccounted for mode ' + @model.get 'mode' if @model.get('mode')?
