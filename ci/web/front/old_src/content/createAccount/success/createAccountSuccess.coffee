window.CreateAccountSuccess = {}


class CreateAccountSuccess.Model extends Backbone.Model
	defaults:
		email: ''
		firstName: ''
		lastName: ''


	validate: (attributes) =>
		if typeof attributes.email isnt 'string'
			return new Error 'Invalid email: ' + attributes.email

		if typeof attributes.firstName isnt 'string'
			return new Error 'Invalid first name: ' + attributes.firstName

		if typeof attributes.lastName isnt 'string'
			return new Error 'Invalid last name: ' + attributes.lastName

		return


class CreateAccountSuccess.View extends Backbone.View
	tagName: 'div'
	className: 'createAccountSuccess'
	template: Handlebars.compile '<div class="emailSentMessage">
				Congratulations {{firstName}} {{lastName}}, an email has been sent to {{email}}!
			</div>'


	initialize: () =>
		@model.on 'change', @render, @


	onDispose: () =>
		@model.off null, null, @


	render: () =>
		@$el.html @template
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
			email: @model.get 'email'
		return @
		