window.LoginCreateAccountEmailSentPanel = {}


class LoginCreateAccountEmailSentPanel.Model extends Backbone.Model
	defaults:
		firstName: 'firstname'
		lastName: 'lastname'
		email: 'email'


class LoginCreateAccountEmailSentPanel.View extends Backbone.View
	tagName: 'div'
	className: 'loginCreateAccountEmailSentPanel'
	template: Handlebars.compile '<p>Thanks {{firstName}} {{lastName}}!
		An email has been sent to {{email}} for you to verify your account!</p>'

	initialize: () =>
		@model.on 'change', () =>
			render()


	render: () =>
		@$el.html @template
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
			email: @model.get 'email'
		return @
