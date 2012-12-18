window.AccountContent = {}


class AccountContent.Model extends Backbone.Model
	defaults:
		view: 'general'


	initialize: () =>
		@accountGeneralPanelModel = new AccountGeneralPanel.Model()
		@accountSshKeysPanelModel = new AccountSshKeysPanel.Model()


class AccountContent.View extends Backbone.View
	tagName: 'div'
	className: 'accountContent'
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
				@currentView = new AccountGeneralPanel.View model: @model.accountGeneralPanelModel
				@$el.html @currentView.render().el
			when 'sshKeys'
				@currentView = new AccountSshKeysPanel.View model: @model.accountSshKeysPanelModel
				@$el.html @currentView.render().el
			else
				@currentView = null
				@$el.html '&nbsp'
				console.error 'Unaccounted for view ' + @model.get 'view'