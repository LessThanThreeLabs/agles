window.Account = {}


class Account.Model extends Backbone.Model
	
	initialize: () =>
		menuOptions = [new PrettyMenuOption('general', 'General'),
			new PrettyMenuOption('ssh', 'SSH Keys')]

		@prettyMenuModel = new PrettyMenu.Model
			options: menuOptions
			selectedOptionName: menuOptions[0].name


class Account.View extends Backbone.View
	tagName: 'div'
	className: 'account'
	html: 'hello'


	render: () =>
		@$el.html @html
		return @
