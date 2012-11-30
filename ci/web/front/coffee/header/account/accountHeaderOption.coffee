window.AccountHeaderOption = {}


class AccountHeaderOption.Model extends Backbone.Model
	defaults:
		firstName: 'first'
		lastName: 'last'
		visible: false


class AccountHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'accountHeaderOption headerMenuOption'
	template: Handlebars.compile '{{firstName}} {{lastName}}'
	events: 'click': '_clickHandler'


	initialize: () =>
		@model.on 'change:firstName', @render, @
		@model.on 'change:lastName', @render, @
		@model.on 'change:visible', @_fixVisibility, @

		window.globalAccount.on 'change:firstName', (() =>
			@model.set 'firstName', window.globalAccount.get 'firstName'
			@model.set 'visible', true
			), @
		window.globalAccount.on 'change:lastName', (() =>
			@model.set 'lastName', window.globalAccount.get 'lastName'
			@model.set 'visible', true
			), @


	onDispose: () =>
		@model.off null, null, @
		window.globalAccount.off null, null, @


	render: () =>
		@$el.html @template
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
		@_fixVisibility()
		return @


	_fixVisibility: () =>
		@$el.css 'display', if @model.get('visible') then 'inline-block' else 'none'


	_clickHandler: () =>
		window.globalRouterModel.set 'view', 'account'
		