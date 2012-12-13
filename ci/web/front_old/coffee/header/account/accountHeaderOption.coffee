window.AccountHeaderOption = {}


class AccountHeaderOption.Model extends Backbone.Model
	defaults:
		firstName: 'first'
		lastName: 'last'
		visible: false


	updateInformation: () =>
		@set 'firstName', globalAccount.get 'firstName'
		@set 'lastName', globalAccount.get 'lastName'
		@set 'visible', globalAccount.get('email')?


class AccountHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'accountHeaderOption headerMenuOption'
	template: Handlebars.compile '{{firstName}} {{lastName}}'
	events: 'click': '_clickHandler'


	initialize: () =>
		@model.on 'change', @render, @
		globalAccount.on 'change', @model.updateInformation, @

		@model.updateInformation()


	onDispose: () =>
		@model.off null, null, @
		globalAccount.off null, null, @


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
		