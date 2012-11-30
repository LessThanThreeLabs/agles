window.LoginHeaderOption = {}


class LoginHeaderOption.Model extends Backbone.Model
	defaults:
		visible: true


	initialize: () ->
		@loginPanelModel = new LoginPanel.Model()


class LoginHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'loginHeaderOption headerMenuOption'
	html: 'Login'
	events: 'click': '_clickHandler'


	initialize: () ->
		@loginPanelView = new LoginPanel.View model: @model.loginPanelModel

		@model.on 'change:visible', @_fixVisibility, @

		window.globalAccount.on 'change:firstName', (() =>
			@model.set 'visible', false
			), @


	onDispose: () =>
		@model.off null, null, @
		window.globalAccount.off null, null, @
		@loginPanelView.dispose()


	render: () ->
		@$el.html @html
		@_addLoginPanelViewToBody()
		return @


	_addLoginPanelViewToBody: () =>
		$('body').append @loginPanelView.render().el


	_clickHandler: () =>
		@model.loginPanelModel.toggleVisibility()


	_fixVisibility: () =>
		@$el.toggle @model.get 'visible'
