window.AccountContent = {}


class AccountContent.Model extends Backbone.Model
	
	initialize: () =>
		


class AccountContent.View extends Backbone.View
	tagName: 'div'
	className: 'accountContent'
	html: 'hello'


	initialize: () =>
		


	onDispose: () =>


	render: () =>
		@$el.html @html
		return @
