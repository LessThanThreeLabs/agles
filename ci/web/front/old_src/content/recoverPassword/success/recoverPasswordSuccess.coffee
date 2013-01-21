window.RecoverPasswordSuccess = {}


class RecoverPasswordSuccess.Model extends Backbone.Model
	defaults:
		email: ''


	validate: (attributes) =>
		if typeof attributes.email isnt 'string'
			return new Error 'Invalid email: ' + attributes.email

		return


class RecoverPasswordSuccess.View extends Backbone.View
	tagName: 'div'
	className: 'recoverPasswordSuccess'
	template: Handlebars.compile '<div class="recovePasswordEmailSentMessage">
				An email has been sent to {{email}} with a new password.
			</div>'


	initialize: () =>
		@model.on 'change', @render, @


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @template
			email: @model.get 'email'
		return @
		