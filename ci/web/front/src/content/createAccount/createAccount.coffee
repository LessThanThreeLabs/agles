window.CreateAccount = {}


class CreateAccount.Model extends Backbone.Model
	

class CreateAccount.View extends Backbone.View
	tagName: 'div'
	className: 'createAccount'
	html: 'sup'


	render: () =>
		@$el.html @html
		return @
		