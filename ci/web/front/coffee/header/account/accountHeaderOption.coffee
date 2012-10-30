window.AccountHeaderOption = {}


class AccountHeaderOption.Model extends Backbone.Model
	defaults:
		firstName: 'first'
		lastName: 'last'
		visible: false

	initialize: () =>
		window.globalAccount.on 'change:firstName', (model, firstName) =>
			@set 'firstName', firstName
			@set 'visible', true
		window.globalAccount.on 'change:lastName', (model, lastName) =>
			@set 'lastName', lastName
			@set 'visible', true


class AccountHeaderOption.View extends Backbone.View
	tagName: 'div'
	className: 'accountHeaderOption headerMenuOption'
	template: Handlebars.compile '{{firstName}} {{lastName}}'
	events: 'click': '_clickHandler'


	initialize: () ->
		@model.on 'change:firstName change:lastName', () =>
			@render()
		@model.on 'change:visible', () =>
			@_fixVisibility()


	render: () ->
		@$el.html @template
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
		@_fixVisibility()
		return @


	_fixVisibility: () =>
		if @model.get('visible') then @$el.css 'display', 'inline-block'
		else @$el.css 'display', 'none'


	_clickHandler: () =>
		console.log 'clicked'
