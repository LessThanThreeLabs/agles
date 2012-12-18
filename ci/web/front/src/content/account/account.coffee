window.Account = {}


class Account.Model extends Backbone.Model
	
	initialize: () =>
		menuOptions = [new PrettyMenuOption('general', 'General'),
			new PrettyMenuOption('sshKeys', 'SSH Keys')]

		@prettyMenuModel = new PrettyMenu.Model
			options: menuOptions
			selectedOptionName: menuOptions[0].name

		@prettyMenuModel.on 'change:selectedOptionName', () =>
			globalRouterModel.set 'view', @prettyMenuModel.get('selectedOptionName'),
				error: (model, error) => console.error error


class Account.View extends Backbone.View
	tagName: 'div'
	className: 'account'
	html: 'hello'


	initialize: () =>
		@prettyMenuView = new PrettyMenu.View model: @model.prettyMenuModel

		globalRouterModel.on 'change:view', (() =>
			@model.prettyMenuModel.set 'selectedOptionName', globalRouterModel.get 'view'
			), @
		@model.prettyMenuModel.set 'selectedOptionName', globalRouterModel.get 'view'


	onDispose: () =>
		globalRouterModel.off null, null, @


	render: () =>
		@$el.html @html
		@$el.append @prettyMenuView.render().el
		return @
