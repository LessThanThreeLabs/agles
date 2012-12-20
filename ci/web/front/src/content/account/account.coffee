window.Account = {}


class Account.Model extends Backbone.Model
	
	initialize: () =>
		menuOptions = [new PrettyMenuOption('general', 'General'),
			new PrettyMenuOption('password', 'Password'),
			new PrettyMenuOption('sshKeys', 'SSH Keys')]

		@prettyMenuModel = new PrettyMenu.Model
			options: menuOptions
			selectedOptionName: menuOptions[0].name

		@accountContentModel = new AccountContent.Model()

		@prettyMenuModel.on 'change:selectedOptionName', () =>
			@accountContentModel.set 'view', @prettyMenuModel.get 'selectedOptionName'
			globalRouterModel.set 'view', @prettyMenuModel.get('selectedOptionName'),
				error: (model, error) => console.error error
		@accountContentModel.set 'view', @prettyMenuModel.get 'selectedOptionName'


class Account.View extends Backbone.View
	tagName: 'div'
	className: 'account'
	html: '<div class="accountContainer">
			<div class="accountMenuContainer"></div>
			<div class="accountContentContainer"></div>
		</div>'


	initialize: () =>
		@prettyMenuView = new PrettyMenu.View model: @model.prettyMenuModel
		@accountContentView = new AccountContent.View model: @model.accountContentModel

		globalRouterModel.on 'change:view', (() =>
			@model.prettyMenuModel.set 'selectedOptionName', globalRouterModel.get 'view'
			), @
		@model.prettyMenuModel.set 'selectedOptionName', globalRouterModel.get 'view'


	onDispose: () =>
		globalRouterModel.off null, null, @

		@prettyMenuView.dispose()
		@accountContentView.dispose()


	render: () =>
		@$el.html @html
		@$('.accountMenuContainer').html @prettyMenuView.render().el
		@$('.accountContentContainer').html @accountContentView.render().el
		return @
