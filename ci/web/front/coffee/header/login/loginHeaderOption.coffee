window.LoginHeaderOption = {}


class LoginHeaderOption.Model extends Backbone.Model

	initialize: () ->
		@loginPanelModel = new LoginPanel.Model()


class LoginHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'loginHeaderOption headerMenuOption'
	template: Handlebars.compile 'Login'
	events: 'click': '_clickHandler'


	initialize: () ->
		@loginPanelView = new LoginPanel.View model: @model.loginPanelModel


	render: () ->
		@$el.html @template()
		@_addLoginPanelView()
		return @


	_addLoginPanelView: () =>
		$('body').append @loginPanelView.render().el


	_clickHandler: () =>
		@model.loginPanelModel.toggleVisibility()
