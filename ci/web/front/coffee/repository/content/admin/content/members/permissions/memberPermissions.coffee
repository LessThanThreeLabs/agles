window.MemberPermissions = {}


class MemberPermissions.Model extends Backbone.Model
	ALLOWED_PERMISSIONS: ['r', 'r/w', 'r/w/a']

	defaults:
		email: null
		firstName: null
		lastName: null
		permissions: null


	validate: (attributes) =>
		if attributes.permissions not in @ALLOWED_PERMISSIONS
			return new Error 'Invalid member permissions'
		return


class MemberPermissions.View extends Backbone.View
	tagName: 'div'
	className: 'memberPermissions'
	template: Handlebars.compile '{{email}} {{firstName}} {{lastName}}'

	initialize: () =>

	render: () =>
		@$el.html @template
			email: @model.get 'email'
			firstName: @model.get 'firstName'
			lastName: @model.get 'lastName'
		return @
