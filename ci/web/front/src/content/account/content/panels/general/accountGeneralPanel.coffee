window.AccountGeneralPanel = {}


class AccountGeneralPanel.Model extends Backbone.Model
	
	initialize: () =>
		


class AccountGeneralPanel.View extends Backbone.View
	tagName: 'div'
	className: 'accountGeneralPanel'
	html: 'account general'


	initialize: () =>
		


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @
