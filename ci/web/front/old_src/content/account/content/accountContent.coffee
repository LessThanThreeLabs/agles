window.AccountContent = {}


class AccountContent.Model extends Backbone.Model
	defaults:
		view: 'general'


	initialize: () =>
		@accountGeneralPanelModel = new AccountGeneralPanel.Model()
		@accountPasswordPanelModel = new AccountPasswordPanel.Model()
		@accountSshKeysPanelModel = new AccountSshKeysPanel.Model()


class AccountContent.View extends Backbone.View
	tagName: 'div'
	className: 'accountContent'
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
				@_currentView = new AccountGeneralPanel.View model: @model.accountGeneralPanelModel
				@$el.html @_currentView.render().el
			when 'password'
				@_currentView = new AccountPasswordPanel.View model: @model.accountPasswordPanelModel
				@$el.html @_currentView.render().el
			when 'sshKeys'
				@_currentView = new AccountSshKeysPanel.View model: @model.accountSshKeysPanelModel
				@$el.html @_currentView.render().el
			else
				@_currentView = null
				@$el.html '&nbsp'
				console.error 'Unaccounted for view ' + @model.get 'view'