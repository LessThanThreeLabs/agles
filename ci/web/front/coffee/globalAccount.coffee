class GlobalAccount extends Backbone.Model
	defaults:
		firstName: ''
		lastName: ''


	validate: (attributes) =>
		if attributes.firstName is ''
			return new Error 'Invalid first name'
		if attributes.lastName is ''
			return new Error 'Invalid last name'

		return


window.globalAccount = new GlobalAccount()
