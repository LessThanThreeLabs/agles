window.AccountSshKeysPanel = {}


class AccountSshKeysPanel.Model extends Backbone.Model
	
	initialize: () =>
		


class AccountSshKeysPanel.View extends Backbone.View
	tagName: 'div'
	className: 'accountSshKeysPanel'
	html: 'account ssh keys'


	initialize: () =>
		


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @
