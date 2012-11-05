window.LoginHeaderOption = {}


class LoginHeaderOption.Model extends Backbone.Model
	defaults:
		visible: true

	initialize: () ->
		@loginPanelModel = new LoginPanel.Model()

		window.globalAccount.on 'change:firstName', () =>
			@set 'visible', false


class LoginHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'loginHeaderOption headerMenuOption'
	template: Handlebars.compile 'Login'
	events: 'click': '_clickHandler'


	initialize: () ->
		@loginPanelView = new LoginPanel.View model: @model.loginPanelModel

		@model.on 'change:visible', () =>
			@_fixVisibility()


	render: () ->
		@$el.html @template()
		@_addLoginPanelView()
		return @


	_addLoginPanelView: () =>
		$('body').append @loginPanelView.render().el


	_clickHandler: () =>
		@model.loginPanelModel.toggleVisibility()


	_fixVisibility: () =>
		@$el.toggle @model.get 'visible'
